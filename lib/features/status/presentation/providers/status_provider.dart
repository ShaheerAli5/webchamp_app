import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:webchamp_app/features/status/data/models/status_model.dart';
import 'package:webchamp_app/features/status/data/services/status_api_service.dart';

final statusApiServiceProvider = Provider((ref) => StatusApiService(Dio())); // In production, use your shared Dio instance

final statusListProvider = StateNotifierProvider<StatusListNotifier, AsyncValue<List<StatusModel>>>((ref) {
  return StatusListNotifier(ref.watch(statusApiServiceProvider));
});

class StatusListNotifier extends StateNotifier<AsyncValue<List<StatusModel>>> {
  final StatusApiService _apiService;
  StatusListNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchStatuses();
  }

  Future<void> fetchStatuses() async {
    try {
      // Mocking fetch logic - implement GET /status_list.php call here
      // state = AsyncValue.data(fetchedList);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> uploadStatus(File file, String type, String caption) async {
    // Implement upload logic with state updates if needed
  }
}

final uploadProgressProvider = StateProvider<double>((ref) => 0.0);
