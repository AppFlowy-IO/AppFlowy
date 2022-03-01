import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_listener.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:app_flowy/workspace/application/doc/doc_service.dart';
import 'package:app_flowy/workspace/application/doc/share_bloc.dart';
import 'package:app_flowy/workspace/application/doc/share_service.dart';
import 'package:app_flowy/workspace/application/home/home_listen_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:app_flowy/workspace/application/trash/trash_bloc.dart';
import 'package:app_flowy/workspace/application/trash/trash_listener.dart';
import 'package:app_flowy/workspace/application/trash/trash_service.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:app_flowy/workspace/application/view/view_service.dart';
import 'package:app_flowy/workspace/application/workspace/welcome_bloc.dart';
import 'package:app_flowy/workspace/application/workspace/workspace_listener.dart';
import 'package:app_flowy/workspace/application/workspace/workspace_service.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_profile.pb.dart';
import 'package:get_it/get_it.dart';

class HomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerFactoryParam<UserListener, UserProfile, void>(
      (user, _) => UserListener(user: user),
    );

    getIt.registerFactoryParam<HomeListenBloc, UserProfile, void>(
      (user, _) => HomeListenBloc(getIt<UserListener>(param1: user)),
    );

    //
    getIt.registerLazySingleton<HomeStackManager>(() => HomeStackManager());
    getIt.registerFactoryParam<WelcomeBloc, UserProfile, void>(
      (user, _) => WelcomeBloc(
        userService: UserService(),
        userListener: getIt<UserListener>(param1: user),
      ),
    );

    //workspace
    getIt.registerFactoryParam<WorkspaceListener, UserProfile, String>((user, workspaceId) =>
        WorkspaceListener(service: WorkspaceListenerService(user: user, workspaceId: workspaceId)));

    // View
    getIt.registerFactoryParam<ViewListener, View, void>(
      (view, _) => ViewListener(view: view),
    );

    getIt.registerFactoryParam<ViewBloc, View, void>(
      (view, _) => ViewBloc(
        view: view, 
        service: ViewService(),
        listener: getIt<ViewListener>(param1: view),
      ),
    );

    //Menu Bloc
    getIt.registerFactoryParam<MenuBloc, UserProfile, String>(
      (user, workspaceId) => MenuBloc(
        workspaceId: workspaceId,
        service: WorkspaceService(),
        listener: getIt<WorkspaceListener>(param1: user, param2: workspaceId),
      ),
    );

    getIt.registerFactoryParam<MenuUserBloc, UserProfile, void>(
      (user, _) => MenuUserBloc(
        user,
        UserService(),
        getIt<UserListener>(param1: user),
      ),
    );

    // App
    getIt.registerFactoryParam<AppBloc, App, void>(
      (app, _) => AppBloc(
        app: app,
        service: AppService(),
        listener: AppListener(appId: app.id),
      ),
    );

    // Doc
    getIt.registerFactoryParam<DocumentBloc, View, void>(
      (view, _) => DocumentBloc(
        view: view,
        service: DocumentService(),
        listener: getIt<ViewListener>(param1: view),
        trashService: getIt<TrashService>(),
      ),
    );

    // trash
    getIt.registerLazySingleton<TrashService>(() => TrashService());
    getIt.registerLazySingleton<TrashListener>(() => TrashListener());
    getIt.registerFactory<TrashBloc>(
      () => TrashBloc(
        service: getIt<TrashService>(),
        listener: getIt<TrashListener>(),
      ),
    );

    // share
    getIt.registerLazySingleton<ShareService>(() => ShareService());
    getIt.registerFactoryParam<DocShareBloc, View, void>(
        (view, _) => DocShareBloc(view: view, service: getIt<ShareService>()));
  }
}
