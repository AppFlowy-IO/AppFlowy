import 'dart:convert';

import 'package:app_flowy/workspace/domain/i_trash.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/trash_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';
part 'doc_bloc.freezed.dart';

class DocBloc extends Bloc<DocEvent, DocState> {
  final View view;
  final IDoc docManager;
  final IViewListener listener;
  final ITrash trasnManager;
  late Document document;
  StreamSubscription? _subscription;

  DocBloc({
    required this.view,
    required this.docManager,
    required this.listener,
    required this.trasnManager,
  }) : super(DocState.initial());

  @override
  Stream<DocState> mapEventToState(DocEvent event) async* {
    yield* event.map(
      initial: _initial,
      deleted: (Deleted value) async* {
        yield state.copyWith(isDeleted: true);
      },
      restore: (Restore value) async* {
        yield state.copyWith(isDeleted: false);
      },
      deletePermanently: (DeletePermanently value) async* {
        final result = await trasnManager.deleteViews([Tuple2(view.id, TrashType.View)]);
        yield result.fold((l) => state.copyWith(forceClose: true), (r) {
          return state;
        });
      },
      restorePage: (RestorePage value) async* {
        final result = await trasnManager.putback(view.id);
        yield result.fold((l) => state.copyWith(isDeleted: false), (r) {
          return state;
        });
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.stop();

    if (_subscription != null) {
      await _subscription?.cancel();
    }

    // docManager.closeDoc();
    return super.close();
  }

  Stream<DocState> _initial(Initial value) async* {
    listener.deletedNotifier.addPublishListener((result) {
      result.fold(
        (view) => add(const DocEvent.deleted()),
        (error) {},
      );
    });

    listener.restoredNotifier.addPublishListener((result) {
      result.fold(
        (view) => add(const DocEvent.restore()),
        (error) {},
      );
    });

    listener.start();

    final result = await docManager.readDoc();
    yield result.fold(
      (doc) {
        document = _decodeJsonToDocument(doc.data);
        _subscription = document.changes.listen((event) {
          final delta = event.item2;
          final documentDelta = document.toDelta();
          _composeDelta(delta, documentDelta);
        });
        return state.copyWith(loadState: DocLoadState.finish(left(unit)));
      },
      (err) {
        return state.copyWith(loadState: DocLoadState.finish(right(err)));
      },
    );
  }

  // Document _decodeListToDocument(Uint8List data) {
  //   final json = jsonDecode(utf8.decode(data));
  //   final document = Document.fromJson(json);
  //   return document;
  // }

  void _composeDelta(Delta composedDelta, Delta documentDelta) async {
    final json = jsonEncode(composedDelta.toJson());
    Log.debug("doc_id: $view.id - Send json: $json");
    final result = await docManager.composeDelta(json: json);

    result.fold((rustDoc) {
      // final json = utf8.decode(doc.data);
      final rustDelta = Delta.fromJson(jsonDecode(rustDoc.data));
      if (documentDelta != rustDelta) {
        Log.error("Receive : $rustDelta");
        Log.error("Expected : $documentDelta");
      }
    }, (r) => null);
  }

  Document _decodeJsonToDocument(String data) {
    // String d = r'''
    //     "[{"insert":"\n👋 Welcome to AppFlowy!\n"},{"insert":"\n","attributes":{"header":1}},{"insert":"Here are the basics\n"},{"insert":"C","attributes":{"header":2}},{"insert":"lick anywhere and just start typing\n"},{"insert":"H","attributes":{"list":"unchecked"}},{"insert":"ighlight any text, and use the menu at the bottom to style your writing however you like\n"},{"insert":"C","attributes":{"list":"unchecked"}},{"insert":"lick + New Page button at the bottom of your sidebar to add a new page\n"},{"insert":"C","attributes":{"list":"unchecked"}},{"insert":"lick the +  next to any page title in the sidebar to quickly add a new subpage\n"},{"insert":"\n","attributes":{"list":"unchecked"}},{"insert":"Have a question? \n"},{"insert":"C","attributes":{"header":2}},{"insert":"lick the '?' at the bottom right for help and support.\n\nLike AppFlowy? Follow us:\n"},{"insert":"G","attributes":{"header":2}},{"insert":"ithub: https://github.com/AppFlowy-IO/appflowy\n"},{"insert":"T","attributes":{"blockquote":true}},{"insert":"witter: https://twitter.com/appflowy\n"},{"insert":"N","attributes":{"blockquote":true}},{"insert":"ewsletter: https://www.appflowy.io/blog\n"},{"retain":1,"attributes":{"blockquote":true}},{"insert":"\n"}]"
    //     ''';

    final json = jsonDecode(data);
    final document = Document.fromJson(json);
    return document;
  }
}

@freezed
class DocEvent with _$DocEvent {
  const factory DocEvent.initial() = Initial;
  const factory DocEvent.deleted() = Deleted;
  const factory DocEvent.restore() = Restore;
  const factory DocEvent.restorePage() = RestorePage;
  const factory DocEvent.deletePermanently() = DeletePermanently;
}

@freezed
class DocState with _$DocState {
  const factory DocState({
    required DocLoadState loadState,
    required bool isDeleted,
    required bool forceClose,
  }) = _DocState;

  factory DocState.initial() => const DocState(
        loadState: _Loading(),
        isDeleted: false,
        forceClose: false,
      );
}

@freezed
class DocLoadState with _$DocLoadState {
  const factory DocLoadState.loading() = _Loading;
  const factory DocLoadState.finish(Either<Unit, WorkspaceError> successOrFail) = _Finish;
}
