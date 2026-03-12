import 'package:cordis/helpers/codes.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/domain/user.dart';
import 'package:cordis/models/dtos/playlist_dto.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/models/dtos/user_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/repositories/cloud/schedule_repository.dart';
import 'package:cordis/repositories/local/flow_item_repository.dart';
import 'package:cordis/repositories/local/cipher_repository.dart';
import 'package:cordis/repositories/local/playlist_repository.dart';
import 'package:cordis/repositories/local/schedule_repository.dart';
import 'package:cordis/repositories/local/section_repository.dart';
import 'package:cordis/repositories/local/user_repository.dart';
import 'package:cordis/repositories/local/version_repository.dart';
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
  /// Priority is given to the local version, so cloud diff are discarded,
  /// But if the schedule doesn't exist locally, or there are empty fields, it will be created/updated with the cloud version
  Future<int> scheduleToLocal(ScheduleDto scheduleDto) async {
    final ownerUser = await _userRepo.getUserByFirebaseId(
      scheduleDto.ownerFirebaseId,
    );

    if (ownerUser == null) {
      throw Exception(
        'Owner user not found locally for schedule ${scheduleDto.firebaseId}',
      );
    }

    final playlistID = await syncPlaylist(scheduleDto.playlist, ownerUser);

    final scheduleID = await syncSchedule(scheduleDto, playlistID);

    final existingRoles = await _localRepo.getRolesForSchedule(scheduleID);
    for (var role in scheduleDto.roles) {
      Role? existingRole;
      try {
        existingRole = existingRoles.firstWhere((r) => r.name == role.name);
      } catch (e) {
        existingRole = null;
      }
      await syncRole(role, scheduleID, existingRole);
    }

    return scheduleID;
  }

  Future<int> syncSchedule(ScheduleDto scheduleDto, int playlistID) async {
    final schedule = scheduleDto.toDomain(playlistLocalId: playlistID);

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
      for (final section in (mergedVersion.sections ?? {}).values) {
        await _sectionRepo.upsertSection(
          section.copyWith(versionId: existingVersion.id!),
        );
      }
    } else {
      // Version doesn't exist locally, insert it and add it to the playlist
      final versionId = await _versionRepo.insertVersion(
        versionDto.toDomain(cipherId: cipherId),
      );

      for (final section in versionDto.sections.values) {
        await _sectionRepo.insertSection(
          Section.fromFirestore(section).copyWith(versionId: versionId),
        );
      }
      await _playlistRepo.addVersionToPlaylist(playlistID, versionId);
    }
  }

  /// =========================================================================
  /// Syncs changes to a published playlist into firestore
  Future<void> scheduleToCloud(
    Schedule schedule,
    String ownerFirebaseID,
  ) async {
    debugPrint(
      'Syncing schedule ${schedule.id} to cloud for owner $ownerFirebaseID',
    );

    final domainPlaylist = (await _playlistRepo.getPlaylistById(
      schedule.playlistId,
    ))!;

    // Build Item DTOs
    final itemOrder = <String>[];
    final flowItems = <String, FlowItem>{};
    final versions = <String, VersionDto>{};
    for (var item in domainPlaylist.items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = (await _versionRepo.getVersionWithId(
            item.contentId!,
          ));

          if (version == null) break;
          final cipher = (await _cipherRepo.getCipherById(version.cipherId));

          if (cipher == null) break;

          final firebaseID = version.firebaseId ?? generateFirebaseId();
          versions[firebaseID] = version.toDto(cipher);
          itemOrder.add('v:$firebaseID');

          break;
        case PlaylistItemType.flowItem:
          final flowItem = await (_flowRepo.getFlowItem(item.contentId!));

          if (flowItem == null) break;
          flowItems[flowItem.firebaseId] = flowItem;
          itemOrder.add('f:${flowItem.firebaseId}');
          break;
      }
    }

    await _cloudRepo.updateSchedule(
      ownerFirebaseID,
      schedule.toDto(
        domainPlaylist.toDto(
          itemOrder: itemOrder,
          flowItems: flowItems,
          versions: versions,
        ),
      ),
    );
  }
}
