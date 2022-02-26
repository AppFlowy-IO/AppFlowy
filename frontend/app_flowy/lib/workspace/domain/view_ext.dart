import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:app_flowy/workspace/presentation/stack_page/doc/doc_stack_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';

extension ToHomeStackContext on View {
  HomeStackContext stackContext() {
    switch (viewType) {
      case ViewType.QuillDocument:
        return DocumentStackContext(view: this);
      case ViewType.Kanban:
        return DocumentStackContext(view: this);
      default:
        return BlankStackContext();
    }
  }
}

extension ToHomeStackType on View {
  HomeStackType stackType() {
    switch (viewType) {
      case ViewType.QuillDocument:
        return HomeStackType.document;
      case ViewType.Kanban:
        return HomeStackType.kanban;
      default:
        return HomeStackType.blank;
    }
  }
}

extension ViewTypeExtension on ViewType {
  String displayName() {
    switch (this) {
      case ViewType.QuillDocument:
        return "Doc";
      case ViewType.Kanban:
        return "Kanban";
      default:
        return "";
    }
  }

  bool enable() {
    switch (this) {
      case ViewType.QuillDocument:
        return true;
      case ViewType.Kanban:
        return false;
      default:
        return false;
    }
  }
}
