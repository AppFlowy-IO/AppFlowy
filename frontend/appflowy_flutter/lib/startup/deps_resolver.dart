import 'package:appflowy/core/network_monitor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_action_sheet_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_header_bloc.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/service/openai_client.dart';
import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/util/file_picker/file_picker_impl.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/app/prelude.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy/workspace/application/edit_panel/edit_panel_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/menu/prelude.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/user/application/prelude.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/plugins/trash/application/prelude.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

class DependencyResolver {
  static Future<void> resolve(final GetIt getIt) async {
    _resolveUserDeps(getIt);

    _resolveHomeDeps(getIt);

    _resolveFolderDeps(getIt);

    _resolveDocDeps(getIt);

    _resolveGridDeps(getIt);

    _resolveCommonService(getIt);
  }
}

void _resolveCommonService(final GetIt getIt) async {
  getIt.registerFactory<FilePickerService>(() => FilePicker());

  getIt.registerFactoryAsync<OpenAIRepository>(
    () async {
      final result = await UserBackendService.getCurrentUserProfile();
      return result.fold(
        (final l) {
          return HttpOpenAIRepository(
            client: http.Client(),
            apiKey: l.openaiKey,
          );
        },
        (final r) {
          throw Exception('Failed to get user profile: ${r.msg}');
        },
      );
    },
  );
}

void _resolveUserDeps(final GetIt getIt) {
  getIt.registerFactory<AuthService>(() => AuthService());
  getIt.registerFactory<AuthRouter>(() => AuthRouter());

  getIt.registerFactory<SignInBloc>(() => SignInBloc(getIt<AuthService>()));
  getIt.registerFactory<SignUpBloc>(() => SignUpBloc(getIt<AuthService>()));

  getIt.registerFactory<SplashRoute>(() => SplashRoute());
  getIt.registerFactory<EditPanelBloc>(() => EditPanelBloc());
  getIt.registerFactory<SplashBloc>(() => SplashBloc());
  getIt.registerLazySingleton<NetworkListener>(() => NetworkListener());
}

void _resolveHomeDeps(final GetIt getIt) {
  getIt.registerSingleton(FToast());

  getIt.registerSingleton(MenuSharedState());

  getIt.registerFactoryParam<UserListener, UserProfilePB, void>(
    (final user, final _) => UserListener(userProfile: user),
  );

  //
  getIt.registerLazySingleton<HomeStackManager>(() => HomeStackManager());

  getIt.registerFactoryParam<WelcomeBloc, UserProfilePB, void>(
    (final user, final _) => WelcomeBloc(
      userService: UserBackendService(userId: user.id),
      userWorkspaceListener: UserWorkspaceListener(userProfile: user),
    ),
  );

  // share
  getIt.registerLazySingleton<ShareService>(() => ShareService());
  getIt.registerFactoryParam<DocShareBloc, ViewPB, void>(
    (final view, final _) => DocShareBloc(view: view, service: getIt<ShareService>()),
  );
}

void _resolveFolderDeps(final GetIt getIt) {
  //workspace
  getIt.registerFactoryParam<WorkspaceListener, UserProfilePB, String>(
    (final user, final workspaceId) =>
        WorkspaceListener(user: user, workspaceId: workspaceId),
  );

  // ViewPB
  getIt.registerFactoryParam<ViewListener, ViewPB, void>(
    (final view, final _) => ViewListener(view: view),
  );

  getIt.registerFactoryParam<ViewBloc, ViewPB, void>(
    (final view, final _) => ViewBloc(
      view: view,
    ),
  );

  getIt.registerFactoryParam<MenuUserBloc, UserProfilePB, void>(
    (final user, final _) => MenuUserBloc(user),
  );

  //Settings
  getIt.registerFactoryParam<SettingsDialogBloc, UserProfilePB, void>(
    (final user, final _) => SettingsDialogBloc(user),
  );

  // Location
  getIt.registerFactory<SettingsLocationCubit>(
    () => SettingsLocationCubit(),
  );

  //User
  getIt.registerFactoryParam<SettingsUserViewBloc, UserProfilePB, void>(
    (final user, final _) => SettingsUserViewBloc(user),
  );

  // AppPB
  getIt.registerFactoryParam<AppBloc, AppPB, void>(
    (final app, final _) => AppBloc(app: app),
  );

  // trash
  getIt.registerLazySingleton<TrashService>(() => TrashService());
  getIt.registerLazySingleton<TrashListener>(() => TrashListener());
  getIt.registerFactory<TrashBloc>(
    () => TrashBloc(),
  );
}

void _resolveDocDeps(final GetIt getIt) {
// Doc
  getIt.registerFactoryParam<DocumentBloc, ViewPB, void>(
    (final view, final _) => DocumentBloc(view: view),
  );
}

void _resolveGridDeps(final GetIt getIt) {
  getIt.registerFactoryParam<GridHeaderBloc, String, FieldController>(
    (final viewId, final fieldController) => GridHeaderBloc(
      viewId: viewId,
      fieldController: fieldController,
    ),
  );

  getIt.registerFactoryParam<FieldActionSheetBloc, FieldCellContext, void>(
    (final data, final _) => FieldActionSheetBloc(fieldCellContext: data),
  );

  getIt.registerFactoryParam<DatabasePropertyBloc, String, FieldController>(
    (final viewId, final cache) =>
        DatabasePropertyBloc(viewId: viewId, fieldController: cache),
  );
}
