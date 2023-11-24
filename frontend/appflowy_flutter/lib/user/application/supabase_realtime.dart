import 'dart:async';
import 'dart:convert';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_service.dart';

/// A service to manage realtime interactions with Supabase.
///
/// `SupbaseRealtimeService` handles subscribing to table changes in Supabase
/// based on the authentication state of a user. The service is initialized with
/// a reference to a Supabase instance and sets up the necessary subscriptions
/// accordingly.
class SupabaseRealtimeService {
  final Supabase supabase;
  final _authStateListener = UserAuthStateListener();

  bool isLoggingOut = false;

  RealtimeChannel? channel;
  StreamSubscription<AuthState>? authStateSubscription;

  SupabaseRealtimeService({required this.supabase}) {
    _subscribeAuthState();
    _subscribeTablesChanges();

    _authStateListener.start(
      didSignIn: () {
        _subscribeTablesChanges();
        isLoggingOut = false;
      },
      onInvalidAuth: (message) async {
        Log.error(message);
        await getIt<AuthService>().signOut();
        channel?.unsubscribe();
        channel = null;
        if (!isLoggingOut) {
          await runAppFlowy();
        }
      },
    );
  }

  void _subscribeAuthState() {
    final auth = Supabase.instance.client.auth;
    authStateSubscription = auth.onAuthStateChange.listen((state) async {
      Log.info("Supabase auth state change: ${state.event}");
    });
  }

  Future<void> _subscribeTablesChanges() async {
    final result = await UserBackendService.getCurrentUserProfile();
    result.fold((l) => null, (userProfile) {
      Log.info("Start listening supabase table changes");
      // https://supabase.com/docs/guides/realtime/postgres-changes
      final List<ChannelFilter> filters = [
        "document",
        "folder",
        "database",
        "database_row",
        "w_database",
      ]
          .map(
            (name) => ChannelFilter(
              event: 'INSERT',
              schema: 'public',
              table: "af_collab_update_$name",
              filter: 'uid=eq.${userProfile.id}',
            ),
          )
          .toList();

      filters.add(
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: "af_user",
          filter: 'uid=eq.${userProfile.id}',
        ),
      );

      const ops = RealtimeChannelConfig(ack: true);
      channel?.unsubscribe();
      channel = supabase.client.channel("table-db-changes", opts: ops);
      for (final filter in filters) {
        channel?.on(
          RealtimeListenTypes.postgresChanges,
          filter,
          (payload, [ref]) {
            try {
              final jsonStr = jsonEncode(payload);
              final pb = RealtimePayloadPB.create()..jsonStr = jsonStr;
              UserEventPushRealtimeEvent(pb).send();
            } catch (e) {
              Log.error(e);
            }
          },
        );
      }

      channel?.subscribe(
        (status, [err]) {
          Log.info(
            "subscribe channel statue: $status, err: $err",
          );
        },
      );
    });
  }

  Future<void> dispose() async {
    await _authStateListener.stop();
    await authStateSubscription?.cancel();
    await channel?.unsubscribe();
  }
}
