import 'dart:typed_data';

import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

part 'date_bloc.freezed.dart';

class DateTypeOptionBloc extends Bloc<DateTypeOptionEvent, DateTypeOptionState> {
  DateTypeOptionBloc() : super(DateTypeOptionState.initial()) {
    on<DateTypeOptionEvent>(
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
class DateTypeOptionEvent with _$DateTypeOptionEvent {
  const factory DateTypeOptionEvent.initial(Uint8List? typeOptionData) = _InitialField;
}

@freezed
class DateTypeOptionState with _$DateTypeOptionState {
  const factory DateTypeOptionState() = _DateTypeOptionState;

  factory DateTypeOptionState.initial() => DateTypeOptionState();
}
