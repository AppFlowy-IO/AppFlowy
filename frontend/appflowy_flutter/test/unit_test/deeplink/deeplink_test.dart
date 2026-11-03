import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/startup/tasks/deeplink/invitation_deeplink_handler.dart';
import 'package:appflowy/startup/tasks/deeplink/login_deeplink_handler.dart';
import 'package:appflowy/startup/tasks/deeplink/new_note_deeplink_handler.dart';
import 'package:appflowy/startup/tasks/deeplink/open_app_deeplink_handler.dart';
import 'package:appflowy/startup/tasks/deeplink/payment_deeplink_handler.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/note_creation_notifier.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deep link handler: ', () {
    final deepLinkHandlerRegistry = DeepLinkHandlerRegistry.instance
      ..register(LoginDeepLinkHandler())
      ..register(PaymentDeepLinkHandler())
      ..register(InvitationDeepLinkHandler())
      ..register(OpenAppDeepLinkHandler());

    test('invitation deep link handler', () {
      final uri = Uri.parse(
        'appflowy-flutter://invitation-callback?email=lucas@appflowy.com&workspace_id=123',
      );
      deepLinkHandlerRegistry.processDeepLink(
        uri: uri,
        onStateChange: (handler, state) {
          expect(handler, isA<InvitationDeepLinkHandler>());
        },
        onResult: (handler, result) {
          expect(handler, isA<InvitationDeepLinkHandler>());
          expect(result.isSuccess, true);
        },
        onError: (error) {
          expect(error, isNull);
        },
      );
    });

    test('login deep link handler', () {
      final uri =
          Uri.parse('appflowy-flutter://login-callback#access_token=123');
      expect(LoginDeepLinkHandler().canHandle(uri), true);
    });

    test('payment deep link handler', () {
      final uri = Uri.parse('appflowy-flutter://payment-success');
      expect(PaymentDeepLinkHandler().canHandle(uri), true);
    });

    test('unknown deep link handler', () {
      final uri =
          Uri.parse('appflowy-flutter://unknown-callback?workspace_id=123');
      deepLinkHandlerRegistry.processDeepLink(
        uri: uri,
        onStateChange: (handler, state) {},
        onResult: (handler, result) {},
        onError: (error) {
          expect(error, isNotNull);
        },
      );
    });

    test('open app deep link handler', () {
      final uri = Uri.parse('appflowy-flutter://');
      expect(OpenAppDeepLinkHandler().canHandle(uri), true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // NewNoteDeepLinkHandler
  // ─────────────────────────────────────────────────────────────────────────
  group('NewNoteDeepLinkHandler: ', () {
    // Initialise Flutter bindings so Clipboard platform channel is available.
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    late CreateNoteService service;
    late NewNoteDeepLinkHandler handler;

    setUp(() {
      service = CreateNoteService();
      handler = NewNoteDeepLinkHandler(service: service);
    });

    tearDown(() => service.dispose());

    void noop(_, __) {}

    test('canHandle returns true for appflowy-flutter://new', () {
      expect(handler.canHandle(Uri.parse('appflowy-flutter://new')), true);
    });

    test('canHandle returns false for other hosts', () {
      expect(
        handler.canHandle(Uri.parse('appflowy-flutter://invitation-callback')),
        false,
      );
      expect(handler.canHandle(Uri.parse('appflowy-flutter://')), false);
    });

    test('handle populates CreateNoteParams with all provided values',
        () async {
      final uri = Uri.parse(
        'appflowy-flutter://new'
        '?workspace_id=ws-123'
        '&parent_view_id=pv-456'
        '&name=My%20Clipping'
        '&content=Hello%20**world**',
      );

      final result = await handler.handle(uri: uri, onStateChange: noop);

      expect(result.isSuccess, true);
      final params = service.pending;
      expect(params, isNotNull);
      expect(params!.workspaceId, 'ws-123');
      expect(params.parentViewId, 'pv-456');
      expect(params.name, 'My Clipping');
      expect(params.content, 'Hello **world**');
    });

    test('handle defaults name to "New Note" when absent', () async {
      await handler.handle(
        uri: Uri.parse('appflowy-flutter://new'),
        onStateChange: noop,
      );
      expect(service.pending?.name, 'New Note');
    });

    test('handle defaults name to "New Note" when blank', () async {
      await handler.handle(
        uri: Uri.parse('appflowy-flutter://new?name=%20%20'),
        onStateChange: noop,
      );
      expect(service.pending?.name, 'New Note');
    });

    test('handle uses clipboard content when &clipboard flag is present',
        () async {
      await Clipboard.setData(const ClipboardData(text: '# From Clipboard'));

      await handler.handle(
        uri: Uri.parse('appflowy-flutter://new?name=Clip&clipboard'),
        onStateChange: noop,
      );

      expect(service.pending?.content, '# From Clipboard');
    });

    test('clipboard flag takes precedence over &content', () async {
      await Clipboard.setData(const ClipboardData(text: 'clipboard wins'));

      await handler.handle(
        uri: Uri.parse('appflowy-flutter://new?content=ignored&clipboard'),
        onStateChange: noop,
      );

      expect(service.pending?.content, 'clipboard wins');
    });

    test('handle succeeds when clipboard is empty', () async {
      await Clipboard.setData(const ClipboardData(text: ''));

      final result = await handler.handle(
        uri: Uri.parse('appflowy-flutter://new?clipboard'),
        onStateChange: noop,
      );

      expect(result.isSuccess, true);
      final content = service.pending?.content;
      expect(content == null || content.isEmpty, true);
    });

    test('handle leaves workspaceId and parentViewId null when absent',
        () async {
      await handler.handle(
        uri: Uri.parse('appflowy-flutter://new?name=Minimal'),
        onStateChange: noop,
      );
      expect(service.pending?.workspaceId, isNull);
      expect(service.pending?.parentViewId, isNull);
    });

    test('consume clears the pending request', () async {
      await handler.handle(
        uri: Uri.parse('appflowy-flutter://new?name=ToConsume'),
        onStateChange: noop,
      );
      expect(service.pending, isNotNull);

      service.consume();
      expect(service.pending, isNull);
    });
  });
}

      final uri = Uri.parse(
        'appflowy-flutter://invitation-callback?email=lucas@appflowy.com&workspace_id=123',
      );
      deepLinkHandlerRegistry.processDeepLink(
        uri: uri,
        onStateChange: (handler, state) {
          expect(handler, isA<InvitationDeepLinkHandler>());
        },
        onResult: (handler, result) {
          expect(handler, isA<InvitationDeepLinkHandler>());
          expect(result.isSuccess, true);
        },
        onError: (error) {
          expect(error, isNull);
        },
      );
    });

    test('login deep link handler', () {
      final uri =
          Uri.parse('appflowy-flutter://login-callback#access_token=123');
      expect(LoginDeepLinkHandler().canHandle(uri), true);
    });

    test('payment deep link handler', () {
      final uri = Uri.parse('appflowy-flutter://payment-success');
      expect(PaymentDeepLinkHandler().canHandle(uri), true);
    });

    test('unknown deep link handler', () {
      final uri =
          Uri.parse('appflowy-flutter://unknown-callback?workspace_id=123');
      deepLinkHandlerRegistry.processDeepLink(
        uri: uri,
        onStateChange: (handler, state) {},
        onResult: (handler, result) {},
        onError: (error) {
          expect(error, isNotNull);
        },
      );
    });

    test('open app deep link handler', () {
      final uri = Uri.parse('appflowy-flutter://');
      expect(OpenAppDeepLinkHandler().canHandle(uri), true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // NewNoteDeepLinkHandler
  // ─────────────────────────────────────────────────────────────────────────
  group('NewNoteDeepLinkHandler: ', () {
    // Initialise Flutter bindings so Clipboard platform channel is available.
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    setUp(() => createNoteNotifier.value = null);

    final handler = NewNoteDeepLinkHandler();
    void noop(_, __) {}

    test('canHandle returns true for appflowy-flutter://new', () {
      expect(handler.canHandle(Uri.parse('appflowy-flutter://new')), true);
    });

    test('canHandle returns false for other hosts', () {
      expect(
        handler.canHandle(Uri.parse('appflowy-flutter://invitation-callback')),
        false,
      );
      expect(handler.canHandle(Uri.parse('appflowy-flutter://')), false);
    });

    test('handle sets CreateNoteParams with all provided values', () async {
      final uri = Uri.parse(
        'appflowy-flutter://new'
        '?workspace_id=ws-123'
        '&parent_view_id=pv-456'
        '&name=My%20Clipping'
        '&content=Hello%20**world**',
      );

      final result = await handler.handle(uri: uri, onStateChange: noop);

      expect(result.isSuccess, true);
      final params = createNoteNotifier.value;
      expect(params, isNotNull);
      expect(params!.workspaceId, 'ws-123');
      expect(params.parentViewId, 'pv-456');
      expect(params.name, 'My Clipping');
      expect(params.content, 'Hello **world**');
    });

    test('handle defaults name to "New Note" when absent', () async {
      final uri = Uri.parse('appflowy-flutter://new');

      await handler.handle(uri: uri, onStateChange: noop);

      expect(createNoteNotifier.value?.name, 'New Note');
    });

    test('handle defaults name to "New Note" when blank', () async {
      final uri = Uri.parse('appflowy-flutter://new?name=%20%20');

      await handler.handle(uri: uri, onStateChange: noop);

      expect(createNoteNotifier.value?.name, 'New Note');
    });

    test('handle uses clipboard content when &clipboard flag is present',
        () async {
      // Seed the clipboard.
      await Clipboard.setData(const ClipboardData(text: '# From Clipboard'));

      final uri = Uri.parse('appflowy-flutter://new?name=Clip&clipboard');

      await handler.handle(uri: uri, onStateChange: noop);

      expect(createNoteNotifier.value?.content, '# From Clipboard');
    });

    test('clipboard flag takes precedence over &content', () async {
      await Clipboard.setData(const ClipboardData(text: 'clipboard wins'));

      final uri = Uri.parse(
        'appflowy-flutter://new?content=ignored&clipboard',
      );

      await handler.handle(uri: uri, onStateChange: noop);

      expect(createNoteNotifier.value?.content, 'clipboard wins');
    });

    test('handle succeeds when clipboard is empty', () async {
      await Clipboard.setData(const ClipboardData(text: ''));

      final uri = Uri.parse('appflowy-flutter://new?clipboard');

      final result = await handler.handle(uri: uri, onStateChange: noop);

      expect(result.isSuccess, true);
      // content should be null or empty – note creation still proceeds
      final content = createNoteNotifier.value?.content;
      expect(content == null || content.isEmpty, true);
    });

    test('handle sets null workspaceId and parentViewId when absent', () async {
      final uri = Uri.parse('appflowy-flutter://new?name=Minimal');

      await handler.handle(uri: uri, onStateChange: noop);

      final params = createNoteNotifier.value;
      expect(params?.workspaceId, isNull);
      expect(params?.parentViewId, isNull);
    });
  });
}
