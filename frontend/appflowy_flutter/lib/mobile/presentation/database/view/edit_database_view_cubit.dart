import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'edit_database_view_cubit.freezed.dart';

class MobileEditDatabaseViewCubit extends Cubit<MobileDatabaseViewEditorState> {
  MobileEditDatabaseViewCubit()
      : super(
          MobileDatabaseViewEditorState.initial(),
        );

  void changePage(MobileEditDatabaseViewPageEnum newPage) {
    emit(MobileDatabaseViewEditorState(currentPage: newPage));
  }
}

@freezed
class MobileDatabaseViewEditorState with _$MobileDatabaseViewEditorState {
  factory MobileDatabaseViewEditorState({
    required MobileEditDatabaseViewPageEnum currentPage,
  }) = _MobileDatabaseViewEditorState;

  factory MobileDatabaseViewEditorState.initial() =>
      MobileDatabaseViewEditorState(
        currentPage: MobileEditDatabaseViewPageEnum.main,
      );
}

enum MobileEditDatabaseViewPageEnum {
  main,
  fields,
  filter,
  sort,
}
