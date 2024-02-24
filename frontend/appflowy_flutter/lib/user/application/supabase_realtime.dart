import 'dart:async';
import 'dart:convert';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service to manage realtime interactions with Supabase.
///
/// `SupabaseRealtimeService` handles subscribing to table changes in Supabase
/// based on the authentication state of a user. The service is initialized with
/// a reference to a Supabase instance and sets up the necessary subscriptions
/// accordingly.
class SupabaseRealtimeService {
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
        await channel?.unsubscribe();
        channel = null;
        if (!isLoggingOut) {
          isLoggingOut = true;
          await runAppFlowy();
        }
      },
    );
  }

  final Supabase supabase;
  final _authStateListener = UserAuthStateListener();

  bool isLoggingOut = false;

  RealtimeChannel? channel;
  StreamSubscription<AuthState>? authStateSubscription;

  void _subscribeAuthState() {
    final auth = Supabase.instance.client.auth;
    authStateSubscription = auth.onAuthStateChange.listen((state) async {
      Log.info("Supabase auth state change: ${state.event}");
    });
  }

  Future<void> _subscribeTablesChanges() async {
    final result = await UserBackendService.getCurrentUserProfile();
    result.fold(
      (userProfile) {
        Log.info("Start listening supabase table changes");

        // https://supabase.com/docs/guides/realtime/postgres-changes

        const ops = RealtimeChannelConfig(ack: true);
        channel?.unsubscribe();
        channel = supabase.client.channel("table-db-changes", opts: ops);
        for (final name in [
          "document",
          "folder",
          "database",
          "database_row",
          "w_database",
        ]) {
          channel?.onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'af_collab_update_$name',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'uid',
              value: userProfile.id,
            ),
            callback: _onPostgresChangesCallback,
          );
        }

        channel?.onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'af_user',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'uid',
            value: userProfile.id,
          ),
          callback: _onPostgresChangesCallback,
        );

        channel?.subscribe(
          (status, [err]) {
            Log.info(
              "subscribe channel statue: $status, err: $err",
            );
          },
        );
      },
      (_) => null,
    );
  }

  Future<void> dispose() async {
    await _authStateListener.stop();
    await authStateSubscription?.cancel();
    await channel?.unsubscribe();
  }

  void _onPostgresChangesCallback(PostgresChangePayload payload) {
    try {
      final jsonStr = jsonEncode(payload);
      final pb = RealtimePayloadPB.create()..jsonStr = jsonStr;
      UserEventPushRealtimeEvent(pb).send();
    } catch (e) {
      Log.error(e);
    }
  }
}
