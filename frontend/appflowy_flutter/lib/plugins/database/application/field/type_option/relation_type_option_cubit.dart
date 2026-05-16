import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'relation_type_option_cubit.freezed.dart';

class RelationDatabaseListCubit extends Cubit<RelationDatabaseListState> {
  RelationDatabaseListCubit() : super(RelationDatabaseListState.initial()) {
    _loadDatabaseMetas();
  }

  void _loadDatabaseMetas() async {
    final metaPBs = await DatabaseEventGetDatabases()
        .send()
        .fold<List<DatabaseMetaPB>>((s) => s.items, (f) => []);
    final futures = metaPBs.map((meta) {
      return ViewBackendService.getView(meta.viewId).then(
        (result) => result.fold(
          (s) => DatabaseMeta(
            databaseId: meta.databaseId,
            viewId: meta.viewId,
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

    /// id of the view
    required String viewId,

    /// name of the database
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
