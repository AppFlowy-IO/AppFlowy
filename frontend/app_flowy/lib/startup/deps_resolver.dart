import 'package:app_flowy/core/network_monitor.dart';
import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:app_flowy/workspace/application/app/prelude.dart';
import 'package:app_flowy/plugins/doc/application/prelude.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:app_flowy/workspace/application/user/prelude.dart';
import 'package:app_flowy/workspace/application/workspace/prelude.dart';
import 'package:app_flowy/workspace/application/edit_panel/edit_panel_bloc.dart';
import 'package:app_flowy/workspace/application/view/prelude.dart';
import 'package:app_flowy/workspace/application/menu/prelude.dart';
import 'package:app_flowy/workspace/application/settings/prelude.dart';
import 'package:app_flowy/user/application/prelude.dart';
import 'package:app_flowy/user/presentation/router.dart';
import 'package:app_flowy/plugins/trash/application/prelude.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';

import '../plugins/grid/application/field/field_controller.dart';

class DependencyResolver {
  static Future<void> resolve(GetIt getIt) async {
    _resolveUserDeps(getIt);

    _resolveHomeDeps(getIt);

    _resolveFolderDeps(getIt);

    _resolveDocDeps(getIt);

    _resolveGridDeps(getIt);
  }
}

void _resolveUserDeps(GetIt getIt) {
  getIt.registerFactory<AuthService>(() => AuthService());
  getIt.registerFactory<AuthRouter>(() => AuthRouter());

  getIt.registerFactory<SignInBloc>(() => SignInBloc(getIt<AuthService>()));
  getIt.registerFactory<SignUpBloc>(() => SignUpBloc(getIt<AuthService>()));

  getIt.registerFactory<SplashRoute>(() => SplashRoute());
  getIt.registerFactory<EditPanelBloc>(() => EditPanelBloc());
  getIt.registerFactory<SplashBloc>(() => SplashBloc());
  getIt.registerLazySingleton<NetworkListener>(() => NetworkListener());
}

void _resolveHomeDeps(GetIt getIt) {
  getIt.registerSingleton(FToast());

  getIt.registerSingleton(MenuSharedState());

  getIt.registerFactoryParam<UserListener, UserProfilePB, void>(
    (user, _) => UserListener(userProfile: user),
  );

  //
  getIt.registerLazySingleton<HomeStackManager>(() => HomeStackManager());

  getIt.registerFactoryParam<WelcomeBloc, UserProfilePB, void>(
    (user, _) => WelcomeBloc(
      userService: UserService(userId: user.id),
      userWorkspaceListener: UserWorkspaceListener(userProfile: user),
    ),
  );

  // share
  getIt.registerLazySingleton<ShareService>(() => ShareService());
  getIt.registerFactoryParam<DocShareBloc, ViewPB, void>(
      (view, _) => DocShareBloc(view: view, service: getIt<ShareService>()));
}

void _resolveFolderDeps(GetIt getIt) {
  //workspace
  getIt.registerFactoryParam<WorkspaceListener, UserProfilePB, String>(
      (user, workspaceId) =>
          WorkspaceListener(user: user, workspaceId: workspaceId));

  // ViewPB
  getIt.registerFactoryParam<ViewListener, ViewPB, void>(
    (view, _) => ViewListener(view: view),
  );

  getIt.registerFactoryParam<ViewBloc, ViewPB, void>(
    (view, _) => ViewBloc(
      view: view,
    ),
  );

  //Menu
  getIt.registerFactoryParam<MenuBloc, UserProfilePB, String>(
    (user, workspaceId) => MenuBloc(
      workspaceId: workspaceId,
      listener: getIt<WorkspaceListener>(param1: user, param2: workspaceId),
    ),
  );

  getIt.registerFactoryParam<MenuUserBloc, UserProfilePB, void>(
    (user, _) => MenuUserBloc(user),
  );

  //Settings
  getIt.registerFactoryParam<SettingsDialogBloc, UserProfilePB, void>(
    (user, _) => SettingsDialogBloc(user),
  );

  //User
  getIt.registerFactoryParam<SettingsUserViewBloc, UserProfilePB, void>(
    (user, _) => SettingsUserViewBloc(user),
  );

  // AppPB
  getIt.registerFactoryParam<AppBloc, AppPB, void>(
    (app, _) => AppBloc(app: app),
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
}

void _resolveDocDeps(GetIt getIt) {
// Doc
  getIt.registerFactoryParam<DocumentBloc, ViewPB, void>(
    (view, _) => DocumentBloc(
      view: view,
      service: DocumentService(),
      listener: getIt<ViewListener>(param1: view),
      trashService: getIt<TrashService>(),
    ),
  );
}

void _resolveGridDeps(GetIt getIt) {
  // GridPB
  getIt.registerFactoryParam<GridBloc, ViewPB, void>(
    (view, _) => GridBloc(view: view),
  );

  getIt.registerFactoryParam<GridHeaderBloc, String, GridFieldController>(
    (gridId, fieldController) => GridHeaderBloc(
      gridId: gridId,
      fieldController: fieldController,
    ),
  );

  getIt.registerFactoryParam<FieldActionSheetBloc, GridFieldCellContext, void>(
    (data, _) => FieldActionSheetBloc(fieldCellContext: data),
  );

  getIt.registerFactoryParam<TextCellBloc, GridCellController, void>(
    (context, _) => TextCellBloc(
      cellController: context,
    ),
  );

  getIt.registerFactoryParam<SelectOptionCellBloc,
      GridSelectOptionCellController, void>(
    (context, _) => SelectOptionCellBloc(
      cellController: context,
    ),
  );

  getIt.registerFactoryParam<NumberCellBloc, GridCellController, void>(
    (context, _) => NumberCellBloc(
      cellController: context,
    ),
  );

  getIt.registerFactoryParam<DateCellBloc, GridDateCellController, void>(
    (context, _) => DateCellBloc(
      cellController: context,
    ),
  );

  getIt.registerFactoryParam<CheckboxCellBloc, GridCellController, void>(
    (cellData, _) => CheckboxCellBloc(
      service: CellService(),
      cellController: cellData,
    ),
  );

  getIt.registerFactoryParam<GridPropertyBloc, String, GridFieldController>(
    (gridId, cache) => GridPropertyBloc(gridId: gridId, fieldController: cache),
  );
}
