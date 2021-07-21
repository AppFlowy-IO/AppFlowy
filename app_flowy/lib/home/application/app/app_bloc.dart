import 'package:app_flowy/home/domain/i_app.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_event.dart';
part 'app_state.dart';
part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final IApp iAppImpl;
  AppBloc(this.iAppImpl) : super(AppState.initial());

  @override
  Stream<AppState> mapEventToState(
    AppEvent event,
  ) async* {
    yield* event.map(
      initial: (e) async* {
        iAppImpl.startWatching(
          updatedCallback: (name, desc) {},
          addViewCallback: (views) {},
        );
      },
      viewsReceived: (e) async* {
        yield state;
      },
    );
  }
}
