import 'package:app_flowy/home/application/app/app_bloc.dart';
import 'package:app_flowy/home/application/app/app_watch_bloc.dart';
import 'package:app_flowy/home/application/menu/menu_bloc.dart';
import 'package:app_flowy/home/application/menu/menu_watch.dart';
import 'package:app_flowy/home/domain/page_stack/page_stack.dart';
import 'package:app_flowy/home/infrastructure/i_app_impl.dart';
import 'package:app_flowy/home/infrastructure/i_workspace_impl.dart';
import 'package:app_flowy/home/infrastructure/repos/app_repo.dart';
import 'package:app_flowy/home/infrastructure/repos/workspace_repo.dart';
import 'package:get_it/get_it.dart';

class HomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    //
    getIt.registerLazySingleton<HomePageStack>(() => HomePageStack());

    //App
    getIt.registerFactoryParam<AppRepository, String, void>(
        (appId, _) => AppRepository(appId: appId));
    getIt.registerFactoryParam<AppWatchRepository, String, void>(
        (appId, _) => AppWatchRepository(appId: appId));
    getIt.registerFactoryParam<IApp, String, void>(
        (appId, _) => IAppImpl(repo: getIt<AppRepository>(param1: appId)));
    getIt.registerFactoryParam<IAppWatch, String, void>((appId, _) =>
        IAppWatchImpl(repo: getIt<AppWatchRepository>(param1: appId)));

    //workspace
    getIt.registerFactoryParam<WorkspaceRepo, String, void>(
        (workspaceId, _) => WorkspaceRepo(workspaceId: workspaceId));
    getIt.registerFactoryParam<WorkspaceWatchRepo, String, void>(
        (workspaceId, _) => WorkspaceWatchRepo(workspaceId: workspaceId));

    getIt.registerFactoryParam<IWorkspace, String, void>((workspacId, _) =>
        IWorkspaceImpl(repo: getIt<WorkspaceRepo>(param1: workspacId)));
    getIt.registerFactoryParam<IWorkspaceWatch, String, void>((workspacId, _) =>
        IWorkspaceWatchImpl(
            repo: getIt<WorkspaceWatchRepo>(param1: workspacId)));

    //Bloc
    getIt.registerFactoryParam<MenuBloc, String, void>(
        (workspaceId, _) => MenuBloc(getIt<IWorkspace>(param1: workspaceId)));
    getIt.registerFactoryParam<MenuWatchBloc, String, void>((workspaceId, _) =>
        MenuWatchBloc(getIt<IWorkspaceWatch>(param1: workspaceId)));

    getIt.registerFactoryParam<AppBloc, String, void>(
        (appId, _) => AppBloc(getIt<IApp>(param1: appId)));
    getIt.registerFactoryParam<AppWatchBloc, String, void>(
        (appId, _) => AppWatchBloc(getIt<IAppWatch>(param1: appId)));
    // AppWatchBloc
  }
}
