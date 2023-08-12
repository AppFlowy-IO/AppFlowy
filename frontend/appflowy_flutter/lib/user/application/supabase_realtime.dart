import 'dart:async';
import 'dart:convert';

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
  bool isSubscribing = false;
  StreamSubscription<AuthState>? authStateSubscription;

  SupbaseRealtimeService({required this.supabase}) {
    _subscribeAuthState();
  }

  void _subscribeAuthState() {
    final auth = Supabase.instance.client.auth;
    authStateSubscription = auth.onAuthStateChange.listen((state) async {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
          _subscribeTableChanges();
          break;
        case AuthChangeEvent.signedOut:
          channel?.unsubscribe();
          break;
        case AuthChangeEvent.tokenRefreshed:
          _subscribeTableChanges();
          break;
        default:
          break;
      }
    });
  }

  /// Sets up and subscribes to realtime table changes in Supabase.
  ///
  /// Specifically subscribes to 'INSERT' events on the 'public' schema
  /// of the table named 'table-db-changes'. Upon receiving an event,
  /// it encodes the payload and pushes a realtime event.
  void _subscribeTableChanges() {
    channel = supabase.client
        .channel(
      "table-db-changes",
      opts: const RealtimeChannelConfig(ack: true),
    )
        .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'INSERT',
              schema: 'public',
            ), (payload, [ref]) {
      try {
        final jsonStr = jsonEncode(payload);
        final pb = RealtimePayloadPB.create()..jsonStr = jsonStr;
        UserEventPushRealtimeEvent(pb).send();
      } catch (e) {
        Log.error(e);
      }
    });

    channel?.subscribe(
      (status, [err]) {
        Log.info(
          "subscribe channel statue: $status, err: $err",
        );
      },
    );
  }
}
