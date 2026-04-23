import 'package:cordeos/helpers/codes.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/models/dtos/schedule_dto.dart';
import 'package:cordeos/models/dtos/user_dto.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/repositories/cloud/schedule_repository.dart';
import 'package:cordeos/repositories/local/flow_item_repository.dart';
import 'package:cordeos/repositories/local/cipher_repository.dart';
import 'package:cordeos/repositories/local/playlist_repository.dart';
import 'package:cordeos/repositories/local/schedule_repository.dart';
import 'package:cordeos/repositories/local/section_repository.dart';
import 'package:cordeos/repositories/local/user_repository.dart';
import 'package:cordeos/repositories/local/version_repository.dart';
import 'package:flutter/material.dart';

class ScheduleSyncService {
  final _localRepo = LocalScheduleRepository();
  final _cloudRepo = CloudScheduleRepository();
  final _playlistRepo = PlaylistRepository();
  final _userRepo = UserRepository();
  final _flowRepo = FlowItemRepository();
  final _cipherRepo = CipherRepository();
  final _versionRepo = LocalVersionRepository();
  final _sectionRepo = SectionRepository();

  /// Sync owner's schedule to SQLite, so it can be accessed offline and edited
  /// Priority is given to the local version, so cloud diffs are discarded,
  /// But if the schedule doesn't exist locally, or there are empty fields, it will be created/updated with the cloud version
  Future<int> scheduleToLocal(
    ScheduleDto scheduleDto, {
    bool isPublic = true,
  }) async {
    debugPrint("SYNC SERVICE - starting schedule to local");
    debugPrint("\t getting owner local id");
    final ownerUser = await _userRepo.getUserByFirebaseId(
      scheduleDto.ownerFirebaseId,
    );

    if (ownerUser == null) {
      throw Exception(
        'Owner user not found locally for schedule ${scheduleDto.firebaseId}',
      );
    }

    debugPrint("\t syncing playlist");
    final playlistID = await syncPlaylist(scheduleDto.playlist, ownerUser);

    debugPrint("\t syncing schedule");
    final scheduleID = await syncSchedule(scheduleDto, playlistID, isPublic);

    debugPrint("\t fetching roles");
    final existingRoles = await _localRepo.getRolesForSchedule(scheduleID);
    for (var role in scheduleDto.roles) {
      Role? existingRole;
      try {
        existingRole = existingRoles.firstWhere((r) => r.name == role.name);
      } catch (e) {
        existingRole = null;
      }
      debugPrint('\t\t syncing role');
      await syncRole(role, scheduleID, existingRole);
    }

    debugPrint("SYNC SERVICE - finished schedule to local with id $scheduleID");
    return scheduleID;
  }

  Future<int> syncSchedule(
    ScheduleDto scheduleDto,
    int playlistID,
    bool isPublic,
  ) async {
    final schedule = scheduleDto
        .toDomain(playlistLocalId: playlistID)
        .copyWith(isPublic: isPublic);

    final existing = await _localRepo.getScheduleByFirebaseIdOrShareCode(
      scheduleDto.firebaseId!,
      scheduleDto.shareCode,
    );

    int scheduleID;
    if (existing == null) {
      // Schedule doesn't exist locally, insert it
      scheduleID = await _localRepo.insertSchedule(schedule);
    } else {
      // Schedule exists, update it (this will keep local changes if there are any, but fill in any missing fields from the cloud version)
      final merged = existing.mergeWith(schedule);
      await _localRepo.updateSchedule(merged);
      scheduleID = merged.id;
    }
    return scheduleID;
  }

  Future<int> syncRole(
    RoleDto roleDto,
    int scheduleID,
    Role? existingRole,
  ) async {
    final users = <User>[];
    for (var user in roleDto.users) {
      final localUser = await syncUser(user);
      users.add(localUser);
    }

    if (existingRole != null) {
      final cloudEmails = {for (var user in users) user.email};
      final localEmails = {for (var member in existingRole.users) member.email};

      // Remove members not in cloud
      for (var member in existingRole.users) {
        if (!cloudEmails.contains(member.email)) {
          await _localRepo.removeUserFromRole(existingRole.id, member.id!);
        }
      }

      // Add new members from cloud
      for (var user in users) {
        if (!localEmails.contains(user.email)) {
          await _localRepo.insertMember(existingRole.id, user.id!);
        }
      }
      return existingRole.id;
    } else {
      // Role doesn't exist locally, insert it
      final roleID = await _localRepo.insertRole(
        scheduleID,
        Role(name: roleDto.name, users: users, id: -1),
      );
      return roleID;
    }
  }

  Future<User> syncUser(UserDto userDto) async {
    final existing = await _userRepo.getUserByEmail(userDto.email);
    if (existing == null) {
      final user = userDto.toDomain();
      final userID = await _userRepo.createUser(user);
      return user.copyWith(id: userID);
    } else {
      final merged = userDto.toDomain().mergeWith(existing);
      final mergedID = await _userRepo.updateUser(merged);
      return merged.copyWith(id: mergedID);
    }
  }

  Future<int> syncPlaylist(PlaylistDto playlistDto, User ownerUser) async {
    final playlistID = await _playlistRepo.upsertPlaylistMetadata(
      playlistDto.toDomain(ownerUser.id!),
    );

    final existingItems = (await _playlistRepo.getPlaylistById(
      playlistID,
    ))!.items;

    // Upsert each playlist Item in the playlist
    for (var item in playlistDto.getPlaylistItems()) {
      switch (item.type) {
        case PlaylistItemType.flowItem:
          debugPrint("\t\tsyncing flow item");
          final flowItem = playlistDto.flowItems[item.firebaseContentId]!;
          await _flowRepo.upsertFlowItem(
            FlowItem.fromFirestore(
              flowItem,
              firebaseId: item.firebaseContentId,
              playlistId: playlistID,
            ),
          );
          existingItems.remove(
            existingItems.firstWhere(
              (i) =>
                  i.type == PlaylistItemType.flowItem &&
                  i.firebaseContentId == item.firebaseContentId,
              orElse: () => PlaylistItem(
                type: PlaylistItemType.flowItem,
                position: 0,
                duration: Duration.zero,
              ),
            ),
          );
          break;
        case PlaylistItemType.version:
          final versionDto = playlistDto.versions[item.firebaseContentId]!;
          debugPrint("\t\tsyncing version");

          await upsertPlaylistVersion(versionDto, playlistID);
          existingItems.remove(
            existingItems.firstWhere(
              (i) =>
                  i.type == PlaylistItemType.version &&
                  i.firebaseContentId == item.firebaseContentId,
              orElse: () => PlaylistItem(
                type: PlaylistItemType.version,
                position: 0,
                duration: Duration.zero,
              ),
            ),
          );
          break;
      }
    }

    // Remove any versions from the playlist that are not in the cloud version
    for (var item in existingItems) {
      switch (item.type) {
        case PlaylistItemType.flowItem:
          await _flowRepo.deleteFlowItem(item.contentId!);
          break;
        case PlaylistItemType.version:
          await _versionRepo.deleteVersion(item.contentId!);
          break;
      }
    }

    return playlistID;
  }

  Future<void> upsertPlaylistVersion(
    VersionDto versionDto,
    int playlistID,
  ) async {
    /// Ensure cipher exists and is up to date
    int? cipherId = await _cipherRepo.getCipherIdByTitleAuthor(
      title: versionDto.title,
      author: versionDto.author,
    );

    if (cipherId == null) {
      // Cipher doesn't exist locally, insert it
      cipherId = await _cipherRepo.insertPrunedCipher(
        Cipher.fromVersionDto(versionDto),
      );
    } else {
      // Cipher exists, merge it
      final existingCipher = await _cipherRepo.getCipherById(cipherId);
      final mergedCipher = existingCipher!.mergeWith(
        Cipher.fromVersionDto(versionDto).copyWith(id: cipherId),
      );
      await _cipherRepo.updateCipher(mergedCipher);
    }

    // Ensure version exists on SQLite and is up to date
    final existingVersion = await _versionRepo.getVersionWithFirebaseId(
      versionDto.firebaseId!,
    );

    if (existingVersion != null) {
      // Version exists, merge it
      final mergedVersion = existingVersion.mergeWith(
        versionDto.toDomain(cipherId: cipherId),
      );
      await _versionRepo.updateVersion(mergedVersion);

      // Sync sections (upsert)
      final existingSections = await _sectionRepo.getSections(
        existingVersion.id!,
      );

      for (final existingSection in existingSections.values) {
        final cloudSection = versionDto.sections[existingSection.key];

        if (cloudSection == null) {
          // Section doesnt exist in the cloud version, delete it locally
          await _sectionRepo.deleteSection(
            existingSection.versionID,
            existingSection.key,
          );
          await _versionRepo.updateVersion(
            existingVersion.copyWith(
              songStructure: existingVersion.songStructure
                ..remove(existingSection.key),
            ),
          );
        } else {
          await _sectionRepo.upsertSection(
            cloudSection.toDomain(versionID: existingVersion.id!),
          );
        }
      }
    } else {
      // Version doesn't exist locally, insert it and add it to the playlist
      final versionID = await _versionRepo.insertVersion(
        versionDto.toDomain(cipherId: cipherId),
      );

      for (final section in versionDto.sections.values) {
        await _sectionRepo.insertSection(
          section.toDomain(versionID: versionID),
        );
      }
      await _playlistRepo.addVersionToPlaylist(playlistID, versionID);
    }
  }

  /// =========================================================================
  /// Syncs changes to a published schedule into firestore
  Future<void> upsertScheduleToCloud(
    Schedule schedule,
    String ownerFirebaseID,
  ) async {
    debugPrint("SYNC SERVICE - starting schedule to cloud");

    final domainPlaylist = (await _playlistRepo.getPlaylistById(
      schedule.playlistId,
    ))!;

    // Build Item DTOs
    final itemOrder = <String>[];
    final flowItems = <String, Map<String, dynamic>>{};
    final versions = <String, VersionDto>{};
    for (var item in domainPlaylist.items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = (await _versionRepo.getVersionWithId(
            item.contentId!,
          ));

          if (version == null) break;
          final cipher = (await _cipherRepo.getCipherById(version.cipherID));

          if (cipher == null) break;

          final firebaseID = version.firebaseID ?? generateFirebaseId();

          final sections = await _sectionRepo.getSections(version.id!);

          versions[firebaseID] = version.toDto(cipher, sections);
          itemOrder.add('v:$firebaseID');

          break;
        case PlaylistItemType.flowItem:
          final flowItem = await (_flowRepo.getFlowItem(item.contentId!));

          if (flowItem == null) break;
          flowItems[flowItem.firebaseId] = flowItem.toFirestore();
          itemOrder.add('f:${flowItem.firebaseId}');
          break;
      }
    }
    final scheduleDto = schedule.toDto(
      PlaylistDto(
        name: domainPlaylist.name,
        itemOrder: itemOrder,
        flowItems: flowItems,
        versions: versions,
      ),
    );
    debugPrint("\tBuilt scheduleDto");

    try {
      if (schedule.firebaseId == null || schedule.firebaseId!.isEmpty) {
        final newID = await _cloudRepo.publishSchedule(scheduleDto);
        debugPrint(
          '\tSchedule published, updating local schedule with firebase ID $newID',
        );
        await _localRepo.updateSchedule(
          schedule.copyWith(firebaseId: newID, isPublic: true),
        );
      } else {
        await _cloudRepo.update(ownerFirebaseID, scheduleDto);
      }

      debugPrint(
        "SYNC SERVICE - finished schedule to cloud with firestoreID ${schedule.id}",
      );
    } catch (e) {
      debugPrint('Error syncing schedule ${schedule.id} to cloud: $e');
    }
  }
}
