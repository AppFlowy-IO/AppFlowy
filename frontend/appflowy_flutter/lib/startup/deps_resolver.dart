import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/network_monitor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_action_sheet_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_header_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/openai_client.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/auth/supabase_auth_service.dart';
import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/util/file_picker/file_picker_impl.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
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
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

class DependencyResolver {
  static Future<void> resolve(GetIt getIt) async {
    _resolveUserDeps(getIt);

    _resolveHomeDeps(getIt);

    _resolveFolderDeps(getIt);

    _resolveDocDeps(getIt);

    _resolveGridDeps(getIt);

    _resolveCommonService(getIt);
  }
}

void _resolveCommonService(GetIt getIt) async {
  // getIt.registerFactory<KeyValueStorage>(() => RustKeyValue());
  getIt.registerFactory<KeyValueStorage>(() => DartKeyValue());
  getIt.registerFactory<FilePickerService>(() => FilePicker());
  getIt.registerFactory<LocalFileStorage>(() => LocalFileStorage());

  getIt.registerFactoryAsync<OpenAIRepository>(
    () async {
      final result = await UserBackendService.getCurrentUserProfile();
      return result.fold(
        (l) {
          throw Exception('Failed to get user profile: ${l.msg}');
        },
        (r) {
          return HttpOpenAIRepository(
            client: http.Client(),
            apiKey: r.openaiKey,
          );
        },
      );
    },
  );
}

void _resolveUserDeps(GetIt getIt) {
  // getIt.registerFactory<AuthService>(() => AppFlowyAuthService());
  getIt.registerFactory<AuthService>(() => SupabaseAuthService());

  getIt.registerFactory<AuthRouter>(() => AuthRouter());

  getIt.registerFactory<SignInBloc>(
    () => SignInBloc(getIt<AuthService>()),
  );
  getIt.registerFactory<SignUpBloc>(
    () => SignUpBloc(getIt<AuthService>()),
  );

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
      userService: UserBackendService(userId: user.id),
      userWorkspaceListener: UserWorkspaceListener(userProfile: user),
    ),
  );

  // share
  getIt.registerLazySingleton<ShareService>(() => ShareService());
  getIt.registerFactoryParam<DocShareBloc, ViewPB, void>(
    (view, _) => DocShareBloc(view: view, service: getIt<ShareService>()),
  );
}

void _resolveFolderDeps(GetIt getIt) {
  //workspace
  getIt.registerFactoryParam<WorkspaceListener, UserProfilePB, String>(
    (user, workspaceId) =>
        WorkspaceListener(user: user, workspaceId: workspaceId),
  );

  // ViewPB
  getIt.registerFactoryParam<ViewListener, ViewPB, void>(
    (view, _) => ViewListener(view: view),
  );

  getIt.registerFactoryParam<ViewBloc, ViewPB, void>(
    (view, _) => ViewBloc(
      view: view,
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

  // trash
  getIt.registerLazySingleton<TrashService>(() => TrashService());
  getIt.registerLazySingleton<TrashListener>(() => TrashListener());
  getIt.registerFactory<TrashBloc>(
    () => TrashBloc(),
  );
}

void _resolveDocDeps(GetIt getIt) {
// Doc
  getIt.registerFactoryParam<DocumentBloc, ViewPB, void>(
    (view, _) => DocumentBloc(view: view),
  );
}

void _resolveGridDeps(GetIt getIt) {
  getIt.registerFactoryParam<GridHeaderBloc, String, FieldController>(
    (viewId, fieldController) => GridHeaderBloc(
      viewId: viewId,
      fieldController: fieldController,
    ),
  );

  getIt.registerFactoryParam<FieldActionSheetBloc, FieldContext, void>(
    (data, _) => FieldActionSheetBloc(fieldCellContext: data),
  );

  getIt.registerFactoryParam<DatabasePropertyBloc, String, FieldController>(
    (viewId, cache) =>
        DatabasePropertyBloc(viewId: viewId, fieldController: cache),
  );
}
