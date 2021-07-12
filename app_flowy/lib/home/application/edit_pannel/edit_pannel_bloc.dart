import 'package:app_flowy/home/domain/edit_context.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_bloc/flutter_bloc.dart';

part 'edit_pannel_event.dart';
part 'edit_pannel_state.dart';
part 'edit_pannel_bloc.freezed.dart';

class EditPannelBloc extends Bloc<EditPannelEvent, EditPannelState> {
  EditPannelBloc() : super(EditPannelState.initial());

  @override
  Stream<EditPannelState> mapEventToState(
    EditPannelEvent event,
  ) async* {
    yield* event.map(
      startEdit: (e) async* {
        yield state.copyWith(isEditing: true, editContext: some(e.context));
      },
      endEdit: (value) async* {
        yield state.copyWith(isEditing: false, editContext: none());
      },
    );
  }
}
