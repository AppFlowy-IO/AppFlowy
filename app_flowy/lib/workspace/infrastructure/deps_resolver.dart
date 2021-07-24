import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_watch_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_watch.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/infrastructure/i_app_impl.dart';
import 'package:app_flowy/workspace/infrastructure/i_doc_impl.dart';
import 'package:app_flowy/workspace/infrastructure/i_workspace_impl.dart';
import 'package:app_flowy/workspace/infrastructure/repos/app_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/workspace_repo.dart';
import 'package:get_it/get_it.dart';

import 'i_view_impl.dart';

class HomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    //
    getIt.registerLazySingleton<HomePageStack>(() => HomePageStack());

    //App
    getIt.registerFactoryParam<IApp, String, void>(
        (appId, _) => IAppImpl(repo: AppRepository(appId: appId)));
    getIt.registerFactoryParam<IAppWatch, String, void>(
        (appId, _) => IAppWatchImpl(repo: AppWatchRepository(appId: appId)));

    //workspace
    getIt.registerFactoryParam<IWorkspace, String, void>((workspaceId, _) =>
        IWorkspaceImpl(repo: WorkspaceRepo(workspaceId: workspaceId)));
    getIt.registerFactoryParam<IWorkspaceWatch, String, void>((workspacId, _) =>
        IWorkspaceWatchImpl(repo: WorkspaceWatchRepo(workspaceId: workspacId)));

    // View
    getIt.registerFactoryParam<IView, String, void>(
        (viewId, _) => IViewImpl(repo: ViewRepository(viewId: viewId)));
    getIt.registerFactoryParam<IViewWatch, String, void>((viewId, _) =>
        IViewWatchImpl(repo: ViewWatchRepository(viewId: viewId)));

    // Doc
    getIt.registerFactoryParam<IDoc, String, void>(
        (docId, _) => IDocImpl(repo: DocRepository(docId: docId)));

    //Bloc
    getIt.registerFactoryParam<MenuBloc, String, void>(
        (workspaceId, _) => MenuBloc(getIt<IWorkspace>(param1: workspaceId)));
    getIt.registerFactoryParam<MenuWatchBloc, String, void>((workspaceId, _) =>
        MenuWatchBloc(getIt<IWorkspaceWatch>(param1: workspaceId)));

    getIt.registerFactoryParam<AppBloc, String, void>(
        (appId, _) => AppBloc(getIt<IApp>(param1: appId)));
    getIt.registerFactoryParam<AppWatchBloc, String, void>(
        (appId, _) => AppWatchBloc(getIt<IAppWatch>(param1: appId)));

    getIt.registerFactoryParam<ViewBloc, String, void>(
        (viewId, _) => ViewBloc(iViewImpl: getIt<IView>(param1: viewId)));

    // getIt.registerFactoryParam<ViewBloc, String, void>(
    //     (viewId, _) => ViewBloc(iViewImpl: getIt<IView>(param1: viewId)));
  }
}
