import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../offline_queue.dart';
import 'unzolo_state.dart';

/// Streams true when the device has any network connection.
/// On web, connectivity_plus is not supported — always reports online.
/// On reconnect (mobile/desktop): flushes the offline queue then re-syncs all data providers.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  if (kIsWeb) {
    yield true;
    return;
  }

  final connectivity = Connectivity();

  final initial = await connectivity.checkConnectivity();
  bool isOnlineNow_ = initial.any((r) => r != ConnectivityResult.none);
  yield isOnlineNow_;

  bool wasOnline = isOnlineNow_;

  await for (final results in connectivity.onConnectivityChanged) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    yield isOnline;

    if (isOnline && !wasOnline) {
      await OfflineQueue.flush();
      ref.read(tripsProvider.notifier).syncNow();
      ref.read(bookingsProvider.notifier).syncNow();
      ref.read(expensesProvider.notifier).syncNow();
      ref.read(customersProvider.notifier).syncNow();
      ref.read(enquiriesProvider.notifier).syncNow();
    }
    wasOnline = isOnline;
  }
});

/// One-shot async check of current connectivity.
/// Returns true immediately on web (plugin not supported there).
Future<bool> isOnlineNow() async {
  if (kIsWeb) return true;
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}
