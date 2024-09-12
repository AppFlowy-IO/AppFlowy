import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class NetworkListener {
  NetworkListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  Future<void> start() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      Log.error("Couldn't check connectivity status. $e");
      return;
    }
    return _updateConnectionStatus(result);
  }

  Future<void> stop() async {
    await _connectivitySubscription.cancel();
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    NetworkTypePB networkType;
    if (result.contains(ConnectivityResult.mobile)) {
      networkType = NetworkTypePB.Cell;
    } else if (result.contains(ConnectivityResult.wifi)) {
      networkType = NetworkTypePB.Wifi;
    } else if (result.contains(ConnectivityResult.ethernet)) {
      networkType = NetworkTypePB.Ethernet;
    } else if (result.contains(ConnectivityResult.vpn)) {
      networkType = NetworkTypePB.VPN;
    } else if (result.contains(ConnectivityResult.bluetooth)) {
      networkType = NetworkTypePB.Bluetooth;
    } else if (result.contains(ConnectivityResult.other)) {
      networkType = NetworkTypePB.NetworkUnknown;
    } else if (result.contains(ConnectivityResult.none)) {
      networkType = NetworkTypePB.NetworkUnknown;
    } else {
      networkType = NetworkTypePB.NetworkUnknown;
    }
    final state = NetworkStatePB.create()..ty = networkType;
    return UserEventUpdateNetworkState(state).send().then((result) {
      result.fold(
        (l) {
          Log.info('updated network status: ${networkType.name}');
        },
        (e) => Log.error('failed to update network status: $e'),
      );
    });
  }
}
