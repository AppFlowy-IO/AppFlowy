import 'dart:typed_data';

import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

part 'selection_bloc.freezed.dart';

class SelectionTypeOptionBloc extends Bloc<SelectionTypeOptionEvent, SelectionTypeOptionState> {
  SelectionTypeOptionBloc() : super(SelectionTypeOptionState.initial()) {
    on<SelectionTypeOptionEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialField value) async {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class SelectionTypeOptionEvent with _$SelectionTypeOptionEvent {
  const factory SelectionTypeOptionEvent.initial(Uint8List? typeOptionData) = _InitialField;
}

@freezed
class SelectionTypeOptionState with _$SelectionTypeOptionState {
  const factory SelectionTypeOptionState() = _SelectionTypeOptionState;

  factory SelectionTypeOptionState.initial() => SelectionTypeOptionState();
}
