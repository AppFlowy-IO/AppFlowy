part of 'home_bloc.dart';

@freezed
abstract class HomeState implements _$HomeState {
  const factory HomeState({
    required bool isLoading,
    required bool showMenu,
    required PageContext pageContext,
    required Option<EditPannelContext> editContext,
  }) = _HomeState;

  factory HomeState.initial() => HomeState(
        isLoading: false,
        showMenu: true,
        pageContext: const BlankPageContext(),
        editContext: none(),
      );
}
