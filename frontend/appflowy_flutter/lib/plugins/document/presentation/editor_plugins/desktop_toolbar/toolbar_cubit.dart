import 'dart:ui';

import 'package:bloc/bloc.dart';

class ToolbarCubit extends Cubit<ToolbarState> {
  ToolbarCubit(this.onDismissCallback) : super(ToolbarState._());

  final VoidCallback onDismissCallback;

  void dismiss() {
    onDismissCallback.call();
  }
}

class ToolbarState {
  const ToolbarState._();
}
