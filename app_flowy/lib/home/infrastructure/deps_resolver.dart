import 'package:app_flowy/home/application/menu/menu_bloc.dart';
import 'package:app_flowy/home/infrastructure/i_app_impl.dart';
import 'package:app_flowy/home/infrastructure/i_workspace_impl.dart';
import 'package:app_flowy/home/infrastructure/repos/app_repo.dart';
import 'package:app_flowy/home/infrastructure/repos/workspace_repo.dart';
import 'package:get_it/get_it.dart';

class HomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerFactoryParam<WorkspaceRepository, String, void>(
        (workspaceId, _) => WorkspaceRepository(workspaceId: workspaceId));

    getIt.registerFactoryParam<AppRepository, String, void>(
        (appId, _) => AppRepository(appId: appId));

    //Interface implementation
    getIt.registerFactoryParam<IApp, String, void>(
        (appId, _) => IAppImpl(repo: getIt<AppRepository>(param1: appId)));

    getIt.registerFactoryParam<IWorkspace, String, void>((workspacId, _) =>
        IWorkspaceImpl(repo: getIt<WorkspaceRepository>(param1: workspacId)));

    //Bloc
    getIt.registerFactoryParam<MenuBloc, String, void>(
        (workspaceId, _) => MenuBloc(getIt<IWorkspace>(param1: workspaceId)));
  }
}
