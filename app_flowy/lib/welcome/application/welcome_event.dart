part of 'welcome_bloc.dart';

@freezed
abstract class WelcomeEvent with _$WelcomeEvent {
  const factory WelcomeEvent.check() = _Check;
  const factory WelcomeEvent.authCheck() = _AuthCheck;
}
