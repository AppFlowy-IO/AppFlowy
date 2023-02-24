import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-net/network_state.pb.dart';
import 'package:flutter/services.dart';

class NetworkListener {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  NetworkListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> start() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      Log.error('Couldn\'t check connectivity status. $e');
      return;
    }
    return _updateConnectionStatus(result);
  }

  void stop() {
    _connectivitySubscription.cancel();
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
          return NetworkTypePB.Unknown;
      }
    }();
    Log.info("Network type: $networkType");
    final state = NetworkStatePB.create()..ty = networkType;
    NetworkEventUpdateNetworkType(state).send().then((result) {
      result.fold(
        (l) {},
        (e) => Log.error(e),
      );
    });
  }
}
