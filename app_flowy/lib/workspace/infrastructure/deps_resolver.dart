import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_watch_bloc.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_watch.dart';
import 'package:app_flowy/workspace/application/view/doc_watch_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_list_bloc.dart';
import 'package:app_flowy/workspace/application/workspace/welcome_bloc.dart';
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
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:get_it/get_it.dart';

import 'i_user_impl.dart';
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
    getIt.registerFactoryParam<IWorkspace, UserProfile, String>(
        (user, workspaceId) => IWorkspaceImpl(
            repo: WorkspaceRepo(user: user, workspaceId: workspaceId)));
    getIt.registerFactoryParam<IWorkspaceWatch, UserProfile, String>(
        (user, workspaceId) => IWorkspaceWatchImpl(
            repo: WorkspaceWatchRepo(user: user, workspaceId: workspaceId)));

    // View
    getIt.registerFactoryParam<IView, View, void>(
        (view, _) => IViewImpl(repo: ViewRepository(view: view)));
    getIt.registerFactoryParam<IViewWatch, View, void>(
        (view, _) => IViewWatchImpl(repo: ViewWatchRepository(view: view)));

    // Doc
    getIt.registerFactoryParam<IDoc, String, void>(
        (docId, _) => IDocImpl(repo: DocRepository(docId: docId)));

    // User
    getIt.registerFactoryParam<IUser, UserProfile, void>(
        (user, _) => IUserImpl(repo: UserRepo(user: user)));
    getIt.registerFactoryParam<IUserWatch, UserProfile, void>(
        (user, _) => IUserWatchImpl(user: user));

    //Menu Bloc
    getIt.registerFactoryParam<MenuBloc, UserProfile, String>(
        (user, workspaceId) =>
            MenuBloc(getIt<IWorkspace>(param1: user, param2: workspaceId)));
    getIt.registerFactoryParam<MenuWatchBloc, UserProfile, String>(
        (user, workspaceId) => MenuWatchBloc(
            getIt<IWorkspaceWatch>(param1: user, param2: workspaceId)));

    getIt.registerFactoryParam<MenuUserBloc, UserProfile, void>(
        (user, _) => MenuUserBloc(getIt<IUser>(param1: user)));

    //
    getIt.registerFactoryParam<AppBloc, String, void>(
        (appId, _) => AppBloc(getIt<IApp>(param1: appId)));
    getIt.registerFactoryParam<AppWatchBloc, String, void>(
        (appId, _) => AppWatchBloc(getIt<IAppWatch>(param1: appId)));

    getIt.registerFactoryParam<ViewBloc, String, void>(
        (viewId, _) => ViewBloc(iViewImpl: getIt<IView>(param1: viewId)));

    getIt.registerFactoryParam<DocWatchBloc, String, void>(
        (docId, _) => DocWatchBloc(iDocImpl: getIt<IDoc>(param1: docId)));

    getIt.registerFactoryParam<DocBloc, String, void>(
        (docId, _) => DocBloc(getIt<IDoc>(param1: docId)));

    // editor
    getIt.registerFactoryParam<EditorPersistence, String, void>(
        (docId, _) => EditorPersistenceImpl(repo: DocRepository(docId: docId)));

    getIt.registerFactoryParam<ViewListBloc, List<View>, void>(
        (views, _) => ViewListBloc(views: views));

    getIt.registerFactoryParam<WelcomeBloc, UserProfile, void>(
      (user, _) => WelcomeBloc(
        repo: UserRepo(user: user),
        watcher: getIt<IUserWatch>(param1: user),
      ),
    );

    // getIt.registerFactoryParam<ViewBloc, String, void>(
    //     (viewId, _) => ViewBloc(iViewImpl: getIt<IView>(param1: viewId)));
  }
}
