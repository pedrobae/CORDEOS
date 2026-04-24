import 'package:cloud_functions/cloud_functions.dart';
import 'package:cordeos/helpers/guard.dart';
import 'package:cordeos/models/dtos/schedule_dto.dart';
import 'package:cordeos/services/firebase/firestore_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class CloudScheduleRepository {
  static const String _functionsRegion = 'us-central1';

  final FirestoreService _firestoreService = FirestoreService();
  final GuardHelper _guardHelper = GuardHelper();

  CloudScheduleRepository();
  // ===== CREATE =====
  /// Publish a new schedule to Firestore
  /// Returns the generated document ID
  Future<String> publishSchedule(ScheduleDto scheduleDto) async {
    return await _withErrorHandling('publish_schedule', () async {
      await _guardHelper.requireAuth();
      await _guardHelper.requireOwnership(scheduleDto.ownerFirebaseId);

      final docId = await _firestoreService.createDocument(
        collectionPath: 'schedules',
        data: scheduleDto.toFirestore(),
      );

      await FirebaseAnalytics.instance.logEvent(
        name: 'created_schedule',
        parameters: {'scheduleId': docId},
      );

      return docId;
    });
  }

  // ===== READ =====

  /// Fetch schedules of a specific user ID
  /// Used when fetching schedules for a user
  Future<List<ScheduleDto>> fetchSchedulesByUserId(
    String firebaseUserId, {
    bool forceFetch = false,
  }) async {
    return await _withErrorHandling('fetch_user_schedules', () async {
      final querySnapshot = await _firestoreService
          .fetchDocumentsContainingValue(
            collectionPath: 'schedules',
            field: 'collaborators',
            orderField: 'datetime',
            value: firebaseUserId,
          );

      final schedules = <ScheduleDto>[];
      for (var doc in querySnapshot) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        schedules.add(ScheduleDto.fromFirestore(data, id));
      }

      debugPrint(
        'CLOUD SCHEDULE REPO - fetched ${schedules.length} schedules - USER $firebaseUserId',
      );

      // await _cacheService.saveCloudSchedules(schedules, firebaseUserId);
      // await _cacheService.saveLastScheduleLoad(now);

      return schedules;
    });
  }

  /// Fetches a schedule by its ID
  /// Returns null if not found
  /// Used after successfully inserting a share code
  Future<ScheduleDto?> fetchScheduleById(String scheduleId) async {
    return await _withErrorHandling('fetch_schedule_by_id', () async {
      final docSnapshot = await _firestoreService.fetchDocumentById(
        collectionPath: 'schedules',
        documentId: scheduleId,
      );

      if (docSnapshot == null) {
        throw Exception('No schedule found with the provided schedule ID.');
      }

      return ScheduleDto.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    });
  }

  // ===== UPDATE =====
  /// Update an existing schedule in Firestore on the changes map
  Future<void> update(String ownerId, ScheduleDto schedule) async {
    return await _withErrorHandling('update_schedule', () async {
      await _guardHelper.requireAuth();
      await _guardHelper.requireOwnership(ownerId);
      await _firestoreService.updateDocument(
        collectionPath: 'schedules',
        documentId: schedule.firebaseId!,
        data: schedule.toFirestore(),
        merge: false,
      );

      await FirebaseAnalytics.instance.logEvent(
        name: 'updated_schedule',
        parameters: {'scheduleId': schedule.firebaseId!},
      );
      return;
    });
  }

  /// Enter Schedule via Share Code by adding the user as a collaborator
  Future<bool> joinWithCode(String shareCode) async {
    return await _withErrorHandling('join_via_share_code', () async {
      await _guardHelper.requireAuth();

      final functions = FirebaseFunctions.instanceFor(region: _functionsRegion);

      final result = await functions.httpsCallable('joinScheduleWithCode').call(
        <String, dynamic>{'shareCode': shareCode},
      );

      // After successfully joining load the schedule
      if (result.data['success'] == true) {
        return true;
      } else {
        throw Exception(
          'Failed to join schedule with the provided share code.',
        );
      }
    });
  }

  // ===== DELETE =====
  /// Delete a schedule from Firestore
  Future<void> deleteSchedule(String firebaseId, String ownerId) async {
    return await _withErrorHandling('delete_schedule', () async {
      await _guardHelper.requireAuth();
      await _guardHelper.requireOwnership(ownerId);

      await _firestoreService.deleteDocument(
        collectionPath: 'schedules',
        documentId: firebaseId,
      );

      await FirebaseAnalytics.instance.logEvent(
        name: 'deleted_schedule',
        parameters: {'scheduleId': firebaseId},
      );
    });
  }

  // ===== ERROR HANDLING =====
  Future<T> _withErrorHandling<T>(
    String actionDescription,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        await FirebaseAnalytics.instance.logEvent(
          name: 'error_during_$actionDescription',
          parameters: {'error': e.message!},
        );
      }
      if (e is FirebaseException) {
        await FirebaseAnalytics.instance.logEvent(
          name: 'error_during_$actionDescription',
          parameters: {'error': e.message!},
        );
      }
      debugPrint(e.toString());
      rethrow;
    }
  }
}
