import 'dart:async';

import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';

class ViewAncestorCache {
  ViewAncestorCache();

  final Map<String, ViewAncestor> _ancestors = {};

  Future<ViewAncestor> getAncestor(
    String viewId, {
    ValueChanged<ViewAncestor>? onRefresh,
  }) async {
    final cachedAncestor = _ancestors[viewId];
    if (cachedAncestor != null) {
      unawaited(_getAncestor(viewId, onRefresh: onRefresh));
      return cachedAncestor;
    }
    return _getAncestor(viewId);
  }

  Future<ViewAncestor> _getAncestor(
    String viewId, {
    ValueChanged<ViewAncestor>? onRefresh,
  }) async {
    final List<ViewPB> ancestors =
        await ViewBackendService.getViewAncestors(viewId).fold(
      (s) => s.items
          .where((e) => e.parentViewId.isNotEmpty && e.id != viewId)
          .toList(),
      (f) => [],
    );
    final newAncestors = ViewAncestor(
      ancestors: ancestors.map((e) => ViewParent.fromViewPB(e)).toList(),
    );
    _ancestors[viewId] = newAncestors;
    onRefresh?.call(newAncestors);
    return newAncestors;
  }
}

class ViewAncestor {
  const ViewAncestor({required this.ancestors});

  const ViewAncestor.empty() : ancestors = const [];

  final List<ViewParent> ancestors;
}

class ViewParent {
  ViewParent({required this.id, required this.name});

  final String id;
  final String name;

  static ViewParent fromViewPB(ViewPB view) =>
      ViewParent(id: view.id, name: view.nameOrDefault);
}
