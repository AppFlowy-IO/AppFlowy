import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/doc/doc_stack_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';

extension ToHomeStackContext on View {
  HomeStackContext stackContext() {
    switch (viewType) {
      case ViewType.Blank:
        return BlankStackContext();
      case ViewType.Doc:
        return DocStackContext(view: this);
      default:
        return BlankStackContext();
    }
  }
}

extension ToHomeStackType on View {
  HomeStackType stackType() {
    switch (viewType) {
      case ViewType.Blank:
        return HomeStackType.blank;
      case ViewType.Doc:
        return HomeStackType.doc;
      default:
        return HomeStackType.blank;
    }
  }
}
