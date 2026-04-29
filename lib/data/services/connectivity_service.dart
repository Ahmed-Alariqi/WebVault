import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that monitors network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((r) => r != ConnectivityResult.none);
    });
  }

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

// --------------- Providers ---------------

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  // Emit the current connectivity state synchronously first so widgets that
  // open in offline mode get an immediate `false` instead of a `loading`
  // state forever (Connectivity.onConnectivityChanged only fires on change).
  late final StreamController<bool> controller;
  controller = StreamController<bool>(
    onListen: () async {
      try {
        controller.add(await service.isOnline);
      } catch (_) {}
      controller.addStream(service.onConnectivityChanged);
    },
  );
  ref.onDispose(controller.close);
  return controller.stream;
});
