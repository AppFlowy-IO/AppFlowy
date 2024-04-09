import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/row_meta_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'database_document_title_bloc.freezed.dart';

class DatabaseDocumentTitleBloc
    extends Bloc<DatabaseDocumentTitleEvent, DatabaseDocumentTitleState> {
  DatabaseDocumentTitleBloc({
    required this.view,
    required this.rowId,
  })  : _metaListener = RowMetaListener(rowId),
        super(DatabaseDocumentTitleState.initial()) {
    _dispatch();
    _startListening();
    _init();
  }

  final ViewPB view;
  final String rowId;
  final RowMetaListener _metaListener;

  void _dispatch() {
    on<DatabaseDocumentTitleEvent>((event, emit) async {
      event.when(
        didUpdateAncestors: (ancestors) {
          emit(
            state.copyWith(
              ancestors: ancestors,
            ),
          );
        },
        didUpdateRowTitleInfo: (databaseController, rowController, fieldId) {
          emit(
            state.copyWith(
              databaseController: databaseController,
              rowController: rowController,
              fieldId: fieldId,
            ),
          );
        },
        didUpdateRowIcon: (icon) {
          emit(
            state.copyWith(
              icon: icon,
            ),
          );
        },
        updateIcon: (icon) {
          _updateMeta(icon);
        },
      );
    });
  }

  void _startListening() {
    _metaListener.start(
      callback: (rowMeta) {
        if (!isClosed) {
          add(DatabaseDocumentTitleEvent.didUpdateRowIcon(rowMeta.icon));
        }
      },
    );
  }

  void _init() async {
    // get the database controller, row controller and primary field id
    final databaseController = DatabaseController(view: view);
    await databaseController.open().fold(
          (s) => databaseController.setIsLoading(false),
          (f) => null,
        );
    final rowInfo = databaseController.rowCache.getRow(rowId);
    if (rowInfo == null) {
      return;
    }
    final rowController = RowController(
      rowMeta: rowInfo.rowMeta,
      viewId: view.id,
      rowCache: databaseController.rowCache,
    );
    final primaryFieldId =
        await FieldBackendService.getPrimaryField(viewId: view.id).fold(
      (primaryField) => primaryField.id,
      (r) {
        Log.error(r);
        return null;
      },
    );
    if (primaryFieldId != null) {
      add(
        DatabaseDocumentTitleEvent.didUpdateRowTitleInfo(
          databaseController,
          rowController,
          primaryFieldId,
        ),
      );
    }

    // load ancestors
    final ancestors = await ViewBackendService.getViewAncestors(view.id)
        .fold((s) => s.items, (f) => <ViewPB>[]);
    add(DatabaseDocumentTitleEvent.didUpdateAncestors(ancestors));

    // initialize icon
    if (rowInfo.rowMeta.icon.isNotEmpty) {
      add(DatabaseDocumentTitleEvent.didUpdateRowIcon(rowInfo.rowMeta.icon));
    }
  }

  /// Update the meta of the row and the view
  void _updateMeta(String iconURL) {
    RowBackendService(viewId: view.id)
        .updateMeta(
          iconURL: iconURL,
          rowId: rowId,
        )
        .fold((l) => null, (err) => Log.error(err));
  }
}

@freezed
class DatabaseDocumentTitleEvent with _$DatabaseDocumentTitleEvent {
  const factory DatabaseDocumentTitleEvent.didUpdateAncestors(
    List<ViewPB> ancestors,
  ) = _DidUpdateAncestors;
  const factory DatabaseDocumentTitleEvent.didUpdateRowTitleInfo(
    DatabaseController databaseController,
    RowController rowController,
    String fieldId,
  ) = _DidUpdateRowTitleInfo;
  const factory DatabaseDocumentTitleEvent.didUpdateRowIcon(
    String icon,
  ) = _DidUpdateRowIcon;
  const factory DatabaseDocumentTitleEvent.updateIcon(
    String icon,
  ) = _UpdateIcon;
}

@freezed
class DatabaseDocumentTitleState with _$DatabaseDocumentTitleState {
  const factory DatabaseDocumentTitleState({
    required List<ViewPB> ancestors,
    required DatabaseController? databaseController,
    required RowController? rowController,
    required String? fieldId,
    required String? icon,
  }) = _DatabaseDocumentTitleState;

  factory DatabaseDocumentTitleState.initial() =>
      const DatabaseDocumentTitleState(
        ancestors: [],
        databaseController: null,
        rowController: null,
        fieldId: null,
        icon: null,
      );
}
