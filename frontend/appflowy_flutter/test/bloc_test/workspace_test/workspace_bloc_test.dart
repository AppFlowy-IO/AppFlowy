import 'package:appflowy/features/workspace/data/repositories/workspace_repository.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

class MockReminderBloc extends Mock implements ReminderBloc {}

class FakeWorkspaceTypePB extends Fake implements WorkspaceTypePB {}

class FakeReminderEvent extends Fake implements ReminderEvent {}

Future<bool> mockIsBillingEnabled() async => false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeWorkspaceTypePB());
    registerFallbackValue(FakeReminderEvent());
  });

  group('UserWorkspaceBloc', () {
    late MockWorkspaceRepository mockRepository;
    late MockReminderBloc mockReminderBloc;
    late UserProfilePB userProfile;
    UserWorkspaceBloc? bloc;

    setUp(() {
      mockRepository = MockWorkspaceRepository();
      mockReminderBloc = MockReminderBloc();
      userProfile = UserProfilePB()
        ..id = fixnum.Int64(123)
        ..name = 'Test User'
        ..email = 'test@example.com'
        ..userAuthType = AuthTypePB.Local;

      getIt.registerLazySingleton<ReminderBloc>(() => mockReminderBloc);

      when(() => mockReminderBloc.add(any())).thenReturn(null);

      when(() => mockRepository.getCurrentWorkspace()).thenAnswer(
        (_) async => FlowyResult.failure(
          FlowyError()..code = ErrorCode.Internal,
        ),
      );
      when(() => mockRepository.getWorkspaces()).thenAnswer(
        (_) async => FlowyResult.success(<UserWorkspacePB>[]),
      );
      when(
        () => mockRepository.openWorkspace(
          workspaceId: any(named: 'workspaceId'),
          workspaceType: any(named: 'workspaceType'),
        ),
      ).thenAnswer(
        (_) async => FlowyResult.success(null),
      );
      when(
        () => mockRepository.getWorkspaceSubscriptionInfo(
          workspaceId: any(named: 'workspaceId'),
        ),
      ).thenAnswer(
        (_) async => FlowyResult.success(WorkspaceSubscriptionInfoPB()),
      );
    });

    tearDown(() {
      if (bloc != null && !bloc!.isClosed) {
        bloc!.close();
      }

      if (getIt.isRegistered<ReminderBloc>()) {
        getIt.unregister<ReminderBloc>();
      }
    });

    UserWorkspacePB createTestWorkspace({
      required String id,
      required String name,
      String icon = '',
      WorkspaceTypePB workspaceType = WorkspaceTypePB.LocalW,
      int createdAt = 1000,
    }) {
      return UserWorkspacePB()
        ..workspaceId = id
        ..name = name
        ..icon = icon
        ..workspaceType = workspaceType
        ..createdAtTimestamp = fixnum.Int64(createdAt);
    }

    WorkspacePB createCurrentWorkspace({
      required String id,
      required String name,
      int createdAt = 1000,
    }) {
      return WorkspacePB()
        ..id = id
        ..name = name
        ..createTime = fixnum.Int64(createdAt);
    }

    group('initial state', () {
      test('should have correct initial state', () {
        bloc = UserWorkspaceBloc(
          repository: mockRepository,
          userProfile: userProfile,
        );

        expect(bloc!.state.userProfile, equals(userProfile));
        expect(bloc!.state.workspaces, isEmpty);
        expect(bloc!.state.currentWorkspace, isNull);
        expect(bloc!.state.actionResult, isNull);
        expect(bloc!.state.isCollabWorkspaceOn, isFalse);
        expect(bloc!.state.workspaceSubscriptionInfo, isNull);
      });
    });

    group('fetchWorkspaces', () {
      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should fetch workspaces successfully when current workspace exists in list',
        setUp: () {
          final currentWorkspace = createCurrentWorkspace(
            id: 'workspace-1',
            name: 'Workspace 1',
          );
          final workspaces = [
            createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
            createTestWorkspace(id: 'workspace-2', name: 'Workspace 2'),
          ];

          when(() => mockRepository.getCurrentWorkspace()).thenAnswer(
            (_) async => FlowyResult.success(currentWorkspace),
          );
          when(() => mockRepository.getWorkspaces()).thenAnswer(
            (_) async => FlowyResult.success(workspaces),
          );
          when(() => mockRepository.isBillingEnabled()).thenAnswer(
            (_) async => true,
          );
        },
        build: () => UserWorkspaceBloc(
          repository: mockRepository,
          userProfile: userProfile,
        ),
        act: (bloc) => bloc.add(UserWorkspaceEvent.fetchWorkspaces()),
        expect: () => [
          // First: workspaces are loaded
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 && state.currentWorkspace == null,
          ),
          // Second: opening workspace action starts
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 &&
                state.actionResult?.actionType == WorkspaceActionType.open &&
                state.actionResult?.isLoading == true,
          ),
          // Third: opening workspace action completes and currentWorkspace is set
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 &&
                state.currentWorkspace != null &&
                state.currentWorkspace?.workspaceId == 'workspace-1' &&
                state.actionResult?.isLoading == false,
          ),
          // Fourth: subscription info is fetched
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 &&
                state.currentWorkspace?.workspaceId == 'workspace-1' &&
                state.workspaceSubscriptionInfo != null,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.workspaces.length, equals(2));
          expect(
            bloc.state.workspaces.first.workspaceId,
            equals('workspace-1'),
          );
          expect(bloc.state.workspaces.last.workspaceId, equals('workspace-2'));
          expect(
            bloc.state.currentWorkspace?.workspaceId,
            equals('workspace-1'),
          );
        },
      );

      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should handle error when fetching current workspace fails but workspaces succeed',
        setUp: () {
          final workspaces = [
            createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
            createTestWorkspace(id: 'workspace-2', name: 'Workspace 2'),
          ];

          when(() => mockRepository.getCurrentWorkspace()).thenAnswer(
            (_) async => FlowyResult.failure(
              FlowyError()..code = ErrorCode.Internal,
            ),
          );
          when(() => mockRepository.getWorkspaces()).thenAnswer(
            (_) async => FlowyResult.success(workspaces),
          );
          when(() => mockRepository.isBillingEnabled()).thenAnswer(
            (_) async => true,
          );
        },
        build: () => UserWorkspaceBloc(
          repository: mockRepository,
          userProfile: userProfile,
        ),
        act: (bloc) => bloc.add(UserWorkspaceEvent.fetchWorkspaces()),
        expect: () => [
          // First: workspaces are loaded, first workspace becomes current
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 && state.currentWorkspace == null,
          ),
          // Second: opening workspace action starts
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 &&
                state.actionResult?.actionType == WorkspaceActionType.open &&
                state.actionResult?.isLoading == true,
          ),
          // Third: opening workspace action completes and currentWorkspace is set
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 &&
                state.currentWorkspace != null &&
                state.currentWorkspace?.workspaceId == 'workspace-1' &&
                state.actionResult?.isLoading == false,
          ),
          // Fourth: subscription info is fetched
          predicate<UserWorkspaceState>(
            (state) =>
                state.workspaces.length == 2 &&
                state.currentWorkspace?.workspaceId == 'workspace-1' &&
                state.workspaceSubscriptionInfo != null,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.workspaces.length, equals(2));
          expect(
            bloc.state.currentWorkspace?.workspaceId,
            equals('workspace-1'),
          );
        },
      );

      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should handle error when fetching workspaces fails',
        setUp: () {
          when(() => mockRepository.getCurrentWorkspace()).thenAnswer(
            (_) async => FlowyResult.failure(
              FlowyError()..code = ErrorCode.Internal,
            ),
          );
          when(() => mockRepository.getWorkspaces()).thenAnswer(
            (_) async => FlowyResult.failure(
              FlowyError()..code = ErrorCode.Internal,
            ),
          );
        },
        build: () => UserWorkspaceBloc(
          repository: mockRepository,
          userProfile: userProfile,
        ),
        act: (bloc) => bloc.add(UserWorkspaceEvent.fetchWorkspaces()),
        verify: (bloc) {
          expect(bloc.state.workspaces, isEmpty);
          expect(bloc.state.currentWorkspace, isNull);

          verifyNever(() => mockReminderBloc.add(any()));
        },
      );
    });

    group('createWorkspace', () {
      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should create workspace successfully',
        setUp: () {
          final newWorkspace = createTestWorkspace(
            id: 'new-workspace',
            name: 'New Workspace',
          );

          when(
            () => mockRepository.createWorkspace(
              name: 'New Workspace',
              workspaceType: WorkspaceTypePB.LocalW,
            ),
          ).thenAnswer(
            (_) async => FlowyResult.success(newWorkspace),
          );

          when(() => mockRepository.isBillingEnabled()).thenAnswer(
            (_) async => true,
          );
        },
        build: () => UserWorkspaceBloc(
          repository: mockRepository,
          userProfile: userProfile,
        ),
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.createWorkspace(
            name: 'New Workspace',
            workspaceType: WorkspaceTypePB.LocalW,
          ),
        ),
        expect: () => [
          // First: create workspace action starts
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.create &&
                state.actionResult?.isLoading == true,
          ),
          // Second: create workspace action completes, workspace is added
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.create &&
                state.actionResult?.isLoading == false &&
                state.actionResult?.result?.isSuccess == true &&
                state.workspaces.isNotEmpty,
          ),
          // Third: opening workspace action starts
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.open &&
                state.actionResult?.isLoading == true &&
                state.workspaces.isNotEmpty,
          ),
          // Fourth: opening workspace action completes, currentWorkspace is set
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.open &&
                state.actionResult?.isLoading == false &&
                state.currentWorkspace != null &&
                state.currentWorkspace?.workspaceId == 'new-workspace',
          ),
          // Fifth: subscription info is fetched
          predicate<UserWorkspaceState>(
            (state) =>
                state.currentWorkspace?.workspaceId == 'new-workspace' &&
                state.workspaceSubscriptionInfo != null,
          ),
        ],
        verify: (bloc) {
          expect(
            bloc.state.workspaces.any((w) => w.workspaceId == 'new-workspace'),
            isTrue,
          );
        },
      );

      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should handle error when creating workspace fails',
        setUp: () {
          when(
            () => mockRepository.createWorkspace(
              name: any(named: 'name'),
              workspaceType: any(named: 'workspaceType'),
            ),
          ).thenAnswer(
            (_) async => FlowyResult.failure(
              FlowyError()..code = ErrorCode.Internal,
            ),
          );
        },
        build: () => UserWorkspaceBloc(
          repository: mockRepository,
          userProfile: userProfile,
        ),
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.createWorkspace(
            name: 'New Workspace',
            workspaceType: WorkspaceTypePB.LocalW,
          ),
        ),
        expect: () => [
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.create &&
                state.actionResult?.isLoading == true,
          ),
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.create &&
                state.actionResult?.isLoading == false &&
                state.actionResult?.result?.isFailure == true,
          ),
        ],
        verify: (bloc) {
          verifyNever(() => mockReminderBloc.add(any()));
        },
      );
    });

    group('deleteWorkspace', () {
      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should prevent deleting the only workspace',
        setUp: () {
          when(() => mockRepository.getCurrentWorkspace()).thenAnswer(
            (_) async => FlowyResult.success(
              createCurrentWorkspace(id: 'workspace-1', name: 'Workspace 1'),
            ),
          );

          when(() => mockRepository.getWorkspaces()).thenAnswer(
            (_) async => FlowyResult.success([
              createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
            ]),
          );
        },
        build: () {
          final bloc = UserWorkspaceBloc(
            repository: mockRepository,
            userProfile: userProfile,
          );

          bloc.emit(
            bloc.state.copyWith(
              workspaces: [
                createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
              ],
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.deleteWorkspace(workspaceId: 'workspace-1'),
        ),
        expect: () => [
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.delete &&
                state.actionResult?.isLoading == true,
          ),
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.delete &&
                state.actionResult?.isLoading == false &&
                state.actionResult?.result?.isFailure == true,
          ),
        ],
      );

      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should delete workspace successfully when more than one workspace exists',
        setUp: () {
          // Create a sequence of responses for getWorkspaces calls
          var callCount = 0;
          when(
            () => mockRepository.deleteWorkspace(
              workspaceId: any(named: 'workspaceId'),
            ),
          ).thenAnswer(
            (_) async => FlowyResult.success(null),
          );

          when(() => mockRepository.getCurrentWorkspace()).thenAnswer(
            (_) async => FlowyResult.success(
              createCurrentWorkspace(id: 'workspace-1', name: 'Workspace 1'),
            ),
          );

          // Return 2 workspaces on first call (for deletion validation)
          // Return 1 workspace on second call (after deletion)
          when(() => mockRepository.getWorkspaces()).thenAnswer(
            (_) async {
              callCount++;
              if (callCount == 1) {
                return FlowyResult.success([
                  createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
                  createTestWorkspace(id: 'workspace-2', name: 'Workspace 2'),
                ]);
              } else {
                return FlowyResult.success([
                  createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
                ]);
              }
            },
          );

          when(() => mockRepository.isBillingEnabled()).thenAnswer(
            (_) async => true,
          );
        },
        build: () {
          final bloc = UserWorkspaceBloc(
            repository: mockRepository,
            userProfile: userProfile,
          );

          bloc.emit(
            bloc.state.copyWith(
              workspaces: [
                createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
                createTestWorkspace(id: 'workspace-2', name: 'Workspace 2'),
              ],
              currentWorkspace: createTestWorkspace(
                id: 'workspace-1',
                name: 'Workspace 1',
              ),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.deleteWorkspace(workspaceId: 'workspace-2'),
        ),
        expect: () => [
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.delete &&
                state.actionResult?.isLoading == true,
          ),
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.delete &&
                state.actionResult?.isLoading == false &&
                state.actionResult?.result?.isSuccess == true,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.workspaces.length, equals(1));
          expect(
            bloc.state.workspaces.any((w) => w.workspaceId == 'workspace-2'),
            isFalse,
          );
        },
      );
    });

    group('renameWorkspace', () {
      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should rename workspace successfully',
        setUp: () {
          when(
            () => mockRepository.renameWorkspace(
              workspaceId: 'workspace-1',
              name: 'Renamed Workspace',
            ),
          ).thenAnswer(
            (_) async => FlowyResult.success(null),
          );
        },
        build: () {
          final bloc = UserWorkspaceBloc(
            repository: mockRepository,
            userProfile: userProfile,
          );

          bloc.emit(
            bloc.state.copyWith(
              workspaces: [
                createTestWorkspace(id: 'workspace-1', name: 'Original Name'),
              ],
              currentWorkspace: createTestWorkspace(
                id: 'workspace-1',
                name: 'Original Name',
              ),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.renameWorkspace(
            workspaceId: 'workspace-1',
            name: 'Renamed Workspace',
          ),
        ),
        expect: () => [
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.rename &&
                state.actionResult?.isLoading == false &&
                state.workspaces.first.name == 'Renamed Workspace' &&
                state.currentWorkspace?.name == 'Renamed Workspace',
          ),
        ],
      );

      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should handle error when renaming workspace fails',
        setUp: () {
          when(
            () => mockRepository.renameWorkspace(
              workspaceId: 'workspace-1',
              name: 'Renamed Workspace',
            ),
          ).thenAnswer(
            (_) async => FlowyResult.failure(
              FlowyError()..code = ErrorCode.Internal,
            ),
          );
        },
        build: () {
          final bloc = UserWorkspaceBloc(
            repository: mockRepository,
            userProfile: userProfile,
          );

          bloc.emit(
            bloc.state.copyWith(
              workspaces: [
                createTestWorkspace(id: 'workspace-1', name: 'Original Name'),
              ],
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.renameWorkspace(
            workspaceId: 'workspace-1',
            name: 'Renamed Workspace',
          ),
        ),
        expect: () => [
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType == WorkspaceActionType.rename &&
                state.actionResult?.isLoading == false &&
                state.actionResult?.result?.isFailure == true &&
                state.workspaces.first.name == 'Original Name',
          ),
        ],
      );
    });

    group('updateWorkspaceIcon', () {
      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should update workspace icon successfully',
        setUp: () {
          when(
            () => mockRepository.updateWorkspaceIcon(
              workspaceId: 'workspace-1',
              icon: '🚀',
            ),
          ).thenAnswer(
            (_) async => FlowyResult.success(null),
          );
        },
        build: () {
          final bloc = UserWorkspaceBloc(
            repository: mockRepository,
            userProfile: userProfile,
          );

          bloc.emit(
            bloc.state.copyWith(
              workspaces: [
                createTestWorkspace(id: 'workspace-1', name: 'Workspace 1'),
              ],
              currentWorkspace: createTestWorkspace(
                id: 'workspace-1',
                name: 'Workspace 1',
              ),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.updateWorkspaceIcon(
            workspaceId: 'workspace-1',
            icon: '🚀',
          ),
        ),
        expect: () => [
          predicate<UserWorkspaceState>(
            (state) =>
                state.actionResult?.actionType ==
                    WorkspaceActionType.updateIcon &&
                state.actionResult?.isLoading == false &&
                state.workspaces.first.icon == '🚀' &&
                state.currentWorkspace?.icon == '🚀',
          ),
        ],
      );

      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should ignore updating to same icon',
        build: () {
          final bloc = UserWorkspaceBloc(
            repository: mockRepository,
            userProfile: userProfile,
          );

          bloc.emit(
            bloc.state.copyWith(
              workspaces: [
                createTestWorkspace(
                  id: 'workspace-1',
                  name: 'Workspace 1',
                  icon: '🚀',
                ),
              ],
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          UserWorkspaceEvent.updateWorkspaceIcon(
            workspaceId: 'workspace-1',
            icon: '🚀',
          ),
        ),
        expect: () => [],
      );
    });

    group('updateWorkspaceSubscriptionInfo', () {
      blocTest<UserWorkspaceBloc, UserWorkspaceState>(
        'should update subscription info',
        build: () => UserWorkspaceBloc(
          repository: mockRepository,
          userProfile: userProfile,
        ),
        act: (bloc) {
          final subscriptionInfo = WorkspaceSubscriptionInfoPB();

          bloc.add(
            UserWorkspaceEvent.updateWorkspaceSubscriptionInfo(
              workspaceId: 'workspace-1',
              subscriptionInfo: subscriptionInfo,
            ),
          );
        },
        expect: () => [
          predicate<UserWorkspaceState>(
            (state) => state.workspaceSubscriptionInfo != null,
          ),
        ],
      );
    });
  });
}
