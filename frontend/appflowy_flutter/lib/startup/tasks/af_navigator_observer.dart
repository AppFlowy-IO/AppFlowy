import 'package:flutter/material.dart';

class AFNavigatorObserver extends NavigatorObserver {
  final Set<ValueChanged<RouteInfo>> _listeners = {};

  void addListener(ValueChanged<RouteInfo> listener) {
    _listeners.add(listener);
  }

  void removeListener(ValueChanged<RouteInfo> listener) {
    _listeners.remove(listener);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    for (final listener in Set.of(_listeners)) {
      listener(PushRouterInfo(newRoute: route, oldRoute: previousRoute));
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    for (final listener in Set.of(_listeners)) {
      listener(PopRouterInfo(newRoute: route, oldRoute: previousRoute));
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    for (final listener in Set.of(_listeners)) {
      listener(ReplaceRouterInfo(newRoute: newRoute, oldRoute: oldRoute));
    }
  }
}

abstract class RouteInfo {
  RouteInfo({this.oldRoute, this.newRoute});

  final Route? oldRoute;
  final Route? newRoute;
}

class PushRouterInfo extends RouteInfo {
  PushRouterInfo({super.newRoute, super.oldRoute});
}

class PopRouterInfo extends RouteInfo {
  PopRouterInfo({super.newRoute, super.oldRoute});
}

class ReplaceRouterInfo extends RouteInfo {
  ReplaceRouterInfo({super.newRoute, super.oldRoute});
}
