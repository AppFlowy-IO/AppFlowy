import 'dart:async';
import 'dart:convert';

import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service to manage realtime interactions with Supabase.
///
/// `SupbaseRealtimeService` handles subscribing to table changes in Supabase
/// based on the authentication state of a user. The service is initialized with
/// a reference to a Supabase instance and sets up the necessary subscriptions
/// accordingly.
class SupbaseRealtimeService {
  final Supabase supabase;
  RealtimeChannel? channel;
  StreamSubscription<AuthState>? authStateSubscription;

  SupbaseRealtimeService({required this.supabase}) {
    _subscribeAuthState();
  }

  void _subscribeAuthState() {
    final auth = Supabase.instance.client.auth;
    authStateSubscription = auth.onAuthStateChange.listen((state) async {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
          _subscribeTablesChanges();
          break;
        case AuthChangeEvent.signedOut:
          channel?.unsubscribe();
          break;
        case AuthChangeEvent.tokenRefreshed:
          _subscribeTablesChanges();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _subscribeTablesChanges() async {
    final result = await UserBackendService.getCurrentUserProfile();
    result.fold((l) => null, (userProfile) {
      Log.info("Start listening to table changes");
      // https://supabase.com/docs/guides/realtime/postgres-changes
      final filters = [
        "document",
        "folder",
        "database",
        "database_row",
        "w_database",
      ].map(
        (name) => ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: "af_collab_update_$name",
          filter: 'uid=eq.${userProfile.id}',
        ),
      );

      const ops = RealtimeChannelConfig(ack: true);
      channel = supabase.client.channel("table-db-changes", opts: ops);
      for (final filter in filters) {
        channel?.on(
          RealtimeListenTypes.postgresChanges,
          filter,
          (payload, [ref]) {
            try {
              final jsonStr = jsonEncode(payload);
              Log.info("Realtime payload: $jsonStr");
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
}
