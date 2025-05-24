import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';

extension NavigationBlocExtension on String {
  void navigateTo() {
    getIt<ActionNavigationBloc>().add(
      ActionNavigationEvent.performAction(
        action: NavigationAction(objectId: this),
        showErrorToast: true,
      ),
    );
  }
}
