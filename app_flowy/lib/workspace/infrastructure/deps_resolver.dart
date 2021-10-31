import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:app_flowy/workspace/application/trash/trash_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:app_flowy/workspace/application/workspace/welcome_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:app_flowy/workspace/domain/i_trash.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/infrastructure/i_app_impl.dart';
import 'package:app_flowy/workspace/infrastructure/i_doc_impl.dart';
import 'package:app_flowy/workspace/infrastructure/i_trash_impl.dart';
import 'package:app_flowy/workspace/infrastructure/i_workspace_impl.dart';
import 'package:app_flowy/workspace/infrastructure/repos/app_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/trash_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/workspace_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:get_it/get_it.dart';

import 'i_user_impl.dart';
import 'i_view_impl.dart';

class HomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    //
    getIt.registerLazySingleton<HomeStackManager>(() => HomeStackManager());
    getIt.registerFactoryParam<WelcomeBloc, UserProfile, void>(
      (user, _) => WelcomeBloc(
        repo: UserRepo(user: user),
        listener: getIt<IUserListener>(param1: user),
      ),
    );

    //App
    getIt.registerFactoryParam<IApp, String, void>((appId, _) => IAppImpl(repo: AppRepository(appId: appId)));
    getIt.registerFactoryParam<IAppListenr, String, void>(
        (appId, _) => IAppListenerhImpl(repo: AppListenerRepository(appId: appId)));

    //workspace
    getIt.registerFactoryParam<IWorkspace, UserProfile, String>(
        (user, workspaceId) => IWorkspaceImpl(repo: WorkspaceRepo(user: user, workspaceId: workspaceId)));
    getIt.registerFactoryParam<IWorkspaceListener, UserProfile, String>((user, workspaceId) =>
        IWorkspaceListenerImpl(repo: WorkspaceListenerRepo(user: user, workspaceId: workspaceId)));

    // View
    getIt.registerFactoryParam<IView, View, void>((view, _) => IViewImpl(repo: ViewRepository(view: view)));
    getIt.registerFactoryParam<IViewListener, View, void>(
        (view, _) => IViewListenerImpl(repo: ViewListenerRepository(view: view)));
    getIt.registerFactoryParam<ViewBloc, View, void>(
      (view, _) => ViewBloc(
        viewManager: getIt<IView>(param1: view),
        listener: getIt<IViewListener>(param1: view),
      ),
    );

    // Doc
    getIt.registerFactoryParam<IDoc, String, void>((docId, _) => IDocImpl(repo: DocRepository(docId: docId)));

    // User
    getIt.registerFactoryParam<IUser, UserProfile, void>((user, _) => IUserImpl(repo: UserRepo(user: user)));
    getIt.registerFactoryParam<IUserListener, UserProfile, void>((user, _) => IUserListenerImpl(user: user));

    //Menu Bloc
    getIt.registerFactoryParam<MenuBloc, UserProfile, String>(
      (user, workspaceId) => MenuBloc(
        workspaceManager: getIt<IWorkspace>(param1: user, param2: workspaceId),
        listener: getIt<IWorkspaceListener>(param1: user, param2: workspaceId),
      ),
    );

    getIt.registerFactoryParam<MenuUserBloc, UserProfile, void>(
        (user, _) => MenuUserBloc(getIt<IUser>(param1: user), getIt<IUserListener>(param1: user)));

    // App
    getIt.registerFactoryParam<AppBloc, App, void>(
      (app, _) => AppBloc(
        app: app,
        appManager: getIt<IApp>(param1: app.id),
        listener: getIt<IAppListenr>(param1: app.id),
      ),
    );

    // Doc
    getIt.registerFactoryParam<DocBloc, View, void>(
      (view, _) => DocBloc(
        docManager: getIt<IDoc>(param1: view.id),
        listener: getIt<IViewListener>(param1: view),
      ),
    );

    // trash
    getIt.registerLazySingleton<TrashRepo>(() => TrashRepo());
    getIt.registerLazySingleton<TrashListenerRepo>(() => TrashListenerRepo());
    getIt.registerFactory<ITrash>(() => ITrashImpl(repo: getIt<TrashRepo>()));
    getIt.registerFactory<ITrashListener>(() => ITrashListenerImpl(repo: getIt<TrashListenerRepo>()));
    getIt.registerFactory<TrashBloc>(() => TrashBloc(trasnManager: getIt<ITrash>(), listener: getIt<ITrashListener>()));
  }
}
