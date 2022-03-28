import 'package:app_flowy/core/network_monitor.dart';
import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/user/application/user_service.dart';
import 'package:app_flowy/workspace/application/app/prelude.dart';
import 'package:app_flowy/workspace/application/doc/prelude.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/application/grid/row/row_listener.dart';
import 'package:app_flowy/workspace/application/trash/prelude.dart';
import 'package:app_flowy/workspace/application/workspace/prelude.dart';
import 'package:app_flowy/workspace/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/application/view/prelude.dart';
import 'package:app_flowy/workspace/application/home/prelude.dart';
import 'package:app_flowy/workspace/application/menu/prelude.dart';
import 'package:app_flowy/user/application/prelude.dart';
import 'package:app_flowy/user/presentation/router.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/user_profile.pb.dart';
import 'package:get_it/get_it.dart';

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
  getIt.registerFactory<HomeBloc>(() => HomeBloc());
  getIt.registerFactory<EditPannelBloc>(() => EditPannelBloc());
  getIt.registerFactory<SplashBloc>(() => SplashBloc());
  getIt.registerLazySingleton<NetworkListener>(() => NetworkListener());
}

void _resolveHomeDeps(GetIt getIt) {
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

  // share
  getIt.registerLazySingleton<ShareService>(() => ShareService());
  getIt.registerFactoryParam<DocShareBloc, View, void>(
      (view, _) => DocShareBloc(view: view, service: getIt<ShareService>()));
}

void _resolveFolderDeps(GetIt getIt) {
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

  //Menu
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
  getIt.registerFactoryParam<DocumentBloc, View, void>(
    (view, _) => DocumentBloc(
      view: view,
      service: DocumentService(),
      listener: getIt<ViewListener>(param1: view),
      trashService: getIt<TrashService>(),
    ),
  );
}

void _resolveGridDeps(GetIt getIt) {
  // Grid
  getIt.registerFactoryParam<GridBloc, View, void>(
    (view, _) => GridBloc(view: view, service: GridService()),
  );

  getIt.registerFactoryParam<RowBloc, GridRowData, void>(
    (data, _) => RowBloc(
      rowData: data,
      rowlistener: RowListener(rowId: data.rowId),
    ),
  );

  getIt.registerFactoryParam<GridHeaderBloc, String, List<Field>>(
    (gridId, fields) => GridHeaderBloc(
      data: GridHeaderData(gridId: gridId, fields: fields),
      service: FieldService(gridId: gridId),
    ),
  );

  getIt.registerFactoryParam<EditFieldBloc, GridFieldData, void>(
    (data, _) => EditFieldBloc(
      field: data.field,
      service: FieldService(gridId: data.gridId),
    ),
  );

  getIt.registerFactoryParam<CreateFieldBloc, String, void>(
    (gridId, _) => CreateFieldBloc(
      service: FieldService(gridId: gridId),
    ),
  );

  getIt.registerFactoryParam<TextCellBloc, FutureCellData, void>(
    (cellData, _) => TextCellBloc(
      service: CellService(),
      cellData: cellData,
    ),
  );

  getIt.registerFactoryParam<SelectionCellBloc, FutureCellData, void>(
    (cellData, _) => SelectionCellBloc(
      service: CellService(),
      cellData: cellData,
    ),
  );

  getIt.registerFactoryParam<NumberCellBloc, FutureCellData, void>(
    (cellData, _) => NumberCellBloc(
      service: CellService(),
      cellData: cellData,
    ),
  );

  getIt.registerFactoryParam<DateCellBloc, FutureCellData, void>(
    (cellData, _) => DateCellBloc(
      service: CellService(),
      cellData: cellData,
    ),
  );

  getIt.registerFactoryParam<CheckboxCellBloc, FutureCellData, void>(
    (cellData, _) => CheckboxCellBloc(
      service: CellService(),
      cellData: cellData,
    ),
  );

  getIt.registerFactoryParam<FieldTypeSwitchBloc, SwitchFieldContext, void>(
    (context, _) => FieldTypeSwitchBloc(context),
  );

  getIt.registerFactory<SelectionTypeOptionBloc>(
    () => SelectionTypeOptionBloc(),
  );

  getIt.registerFactoryParam<DateTypeOptionBloc, DateTypeOption, void>(
    (typeOption, _) => DateTypeOptionBloc(typeOption: typeOption),
  );

  getIt.registerFactoryParam<NumberTypeOptionBloc, NumberTypeOption, void>(
    (typeOption, _) => NumberTypeOptionBloc(typeOption: typeOption),
  );
}
