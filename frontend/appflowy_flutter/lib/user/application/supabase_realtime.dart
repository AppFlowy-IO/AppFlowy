import 'dart:async';
import 'dart:convert';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _subscribeTableChanges() {
    Log.info("subscribe supabase table changes");
    channel = supabase.client.channel("table-db-changes").onEvents(
        "postgres_changes",
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
        if (status != "SUBSCRIBED") {
          channel?.unsubscribe();
          Log.info("channel subscribe statue: $status, err: $err");

          Future.delayed(const Duration(seconds: 10), () {
            _subscribeTableChanges();
          });
        }
      },
    );
  }
}
