import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).statusChanges;
});

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> hasConnection() async {
    try {
      final result = await _connectivity.checkConnectivity().timeout(
        const Duration(milliseconds: 500),
      );
      return _hasNetwork(result);
    } on TimeoutException {
      return true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  Stream<bool> get statusChanges async* {
    yield await hasConnection();

    yield* _connectivity.onConnectivityChanged
        .map(_hasNetwork)
        .distinct()
        .handleError((_) {});
  }
}

bool _hasNetwork(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
