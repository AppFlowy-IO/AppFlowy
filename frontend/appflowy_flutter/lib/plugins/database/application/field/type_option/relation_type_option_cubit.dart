import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_type_option_cubit.freezed.dart';

class RelationDatabaseListCubit extends Cubit<RelationDatabaseListState> {
  RelationDatabaseListCubit() : super(RelationDatabaseListState.initial()) {
    _loadDatabaseMetas();
  }

  void _loadDatabaseMetas() async {
    final getDatabaseResult = await DatabaseEventGetDatabases().send();
    final metaPBs = getDatabaseResult.fold<List<DatabaseMetaPB>>(
      (s) => s.items,
      (f) => [],
    );
    final futures = metaPBs.map((meta) {
      return ViewBackendService.getView(meta.inlineViewId).then(
        (result) => result.fold(
          (s) => DatabaseMeta(
            databaseId: meta.databaseId,
            inlineViewId: meta.inlineViewId,
            databaseName: s.name,
          ),
          (f) => null,
        ),
      );
    });
    final databaseMetas = await Future.wait(futures);
    emit(
      RelationDatabaseListState(
        databaseMetas: databaseMetas.nonNulls.toList(),
      ),
    );
  }
}

@freezed
class DatabaseMeta with _$DatabaseMeta {
  factory DatabaseMeta({
    /// id of the database
    required String databaseId,

    /// id of the inline view
    required String inlineViewId,

    /// name of the database, currently identical to the name of the inline view
    required String databaseName,
  }) = _DatabaseMeta;
}

@freezed
class RelationDatabaseListState with _$RelationDatabaseListState {
  factory RelationDatabaseListState({
    required List<DatabaseMeta> databaseMetas,
  }) = _RelationDatabaseListState;

  factory RelationDatabaseListState.initial() =>
      RelationDatabaseListState(databaseMetas: []);
}
