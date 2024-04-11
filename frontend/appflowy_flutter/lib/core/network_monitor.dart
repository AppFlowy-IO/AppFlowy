import 'dart:async';

import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:flutter/services.dart';

class NetworkListener {
  NetworkListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> start() async {
    late ConnectivityResult result;
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

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final networkType = () {
      switch (result) {
        case ConnectivityResult.wifi:
          return NetworkTypePB.Wifi;
        case ConnectivityResult.ethernet:
          return NetworkTypePB.Ethernet;
        case ConnectivityResult.mobile:
          return NetworkTypePB.Cell;
        case ConnectivityResult.bluetooth:
          return NetworkTypePB.Bluetooth;
        case ConnectivityResult.vpn:
          return NetworkTypePB.VPN;
        case ConnectivityResult.none:
        case ConnectivityResult.other:
          return NetworkTypePB.NetworkUnknown;
      }
    }();
    final state = NetworkStatePB.create()..ty = networkType;
    return UserEventUpdateNetworkState(state).send().then((result) {
      result.fold((l) {}, (e) => Log.error(e));
    });
  }
}
