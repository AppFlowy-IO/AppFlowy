import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension MobileRouter on BuildContext {
  Future<void> pushView(ViewPB view) async {
    push(
      Uri(
        path: view.routeName,
        queryParameters: view.queryParameters,
      ).toString(),
    );
  }
}

extension on ViewPB {
  String get routeName {
    switch (layout) {
      case ViewLayoutPB.Document:
        return MobileEditorScreen.routeName;
      default:
        throw UnimplementedError('routeName for $this is not implemented');
    }
  }

  Map<String, dynamic> get queryParameters {
    switch (layout) {
      case ViewLayoutPB.Document:
        return {
          MobileEditorScreen.viewId: id,
        };
      default:
        throw UnimplementedError(
          'queryParameters for $this is not implemented',
        );
    }
  }
}
