import 'package:app_flowy/user/domain/interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/errors.pb.dart';
import 'package:flowy_sdk/protobuf/user_detail.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';
part 'sign_in_bloc.freezed.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final IAuth authImpl;
  SignInBloc(this.authImpl) : super(SignInState.initial());

  @override
  Stream<SignInState> mapEventToState(
    SignInEvent event,
  ) async* {
    yield* event.map(
      signedInWithUserEmailAndPassword: (e) async* {
        yield* _performActionOnSignIn(
          state,
        );
      },
      emailChanged: (EmailChanged value) async* {
        yield state.copyWith(email: value.email, signInFailure: none());
      },
      passwordChanged: (PasswordChanged value) async* {
        yield state.copyWith(password: value.password, signInFailure: none());
      },
    );
  }

  Stream<SignInState> _performActionOnSignIn(SignInState state) async* {
    yield state.copyWith(isSubmitting: true);

    final result = await authImpl.signIn(state.email, state.password);
    yield result.fold(
      (userDetail) => state.copyWith(
          isSubmitting: false, signInFailure: some(left(userDetail))),
      (s) => state.copyWith(isSubmitting: false, signInFailure: some(right(s))),
    );
  }
}
