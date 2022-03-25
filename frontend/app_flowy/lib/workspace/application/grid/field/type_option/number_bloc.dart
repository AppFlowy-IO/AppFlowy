import 'dart:typed_data';

import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

part 'number_bloc.freezed.dart';

class NumberTypeOptionBloc extends Bloc<NumberTypeOptionEvent, NumberTypeOptionState> {
  NumberTypeOptionBloc() : super(NumberTypeOptionState.initial()) {
    on<NumberTypeOptionEvent>(
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
class NumberTypeOptionEvent with _$NumberTypeOptionEvent {
  const factory NumberTypeOptionEvent.initial(Uint8List? typeOptionData) = _InitialField;
}

@freezed
class NumberTypeOptionState with _$NumberTypeOptionState {
  const factory NumberTypeOptionState() = _NumberTypeOptionState;

  factory NumberTypeOptionState.initial() => NumberTypeOptionState();
}
