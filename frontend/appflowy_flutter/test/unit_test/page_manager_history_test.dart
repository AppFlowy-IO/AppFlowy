import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageHistoryTracker navigation', () {
    test('initial state has no history', () {
      final tracker = PageHistoryTracker();
      expect(tracker.canGoBack, isFalse);
      expect(tracker.canGoForward, isFalse);
      expect(tracker.goBack(), isNull);
      expect(tracker.goForward(), isNull);
    });

    test('recording single view cannot go back or forward', () {
      final tracker = PageHistoryTracker();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');

      tracker.recordHistory(viewA);
      expect(tracker.canGoBack, isFalse);
      expect(tracker.canGoForward, isFalse);
    });

    test('navigates back and forward across multiple views', () {
      final tracker = PageHistoryTracker();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');
      final viewB = ViewPB(id: 'view-b', name: 'Page B');
      final viewC = ViewPB(id: 'view-c', name: 'Page C');

      tracker.recordHistory(viewA);
      tracker.recordHistory(viewB);
      tracker.recordHistory(viewC);

      expect(tracker.canGoBack, isTrue);
      expect(tracker.canGoForward, isFalse);

      final backToB = tracker.goBack();
      expect(backToB?.id, 'view-b');
      expect(tracker.canGoBack, isTrue);
      expect(tracker.canGoForward, isTrue);

      final backToA = tracker.goBack();
      expect(backToA?.id, 'view-a');
      expect(tracker.canGoBack, isFalse);
      expect(tracker.canGoForward, isTrue);

      final forwardToB = tracker.goForward();
      expect(forwardToB?.id, 'view-b');
      expect(tracker.canGoBack, isTrue);
      expect(tracker.canGoForward, isTrue);

      final forwardToC = tracker.goForward();
      expect(forwardToC?.id, 'view-c');
      expect(tracker.canGoBack, isTrue);
      expect(tracker.canGoForward, isFalse);
    });

    test('ignores consecutive duplicate view records', () {
      final tracker = PageHistoryTracker();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');

      tracker.recordHistory(viewA);
      tracker.recordHistory(viewA);

      expect(tracker.canGoBack, isFalse);
    });

    test('branching history truncates forward stack', () {
      final tracker = PageHistoryTracker();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');
      final viewB = ViewPB(id: 'view-b', name: 'Page B');
      final viewC = ViewPB(id: 'view-c', name: 'Page C');

      tracker.recordHistory(viewA);
      tracker.recordHistory(viewB);

      tracker.goBack(); // back to A
      expect(tracker.canGoForward, isTrue);

      tracker.recordHistory(viewC); // record C while at A
      expect(tracker.canGoForward, isFalse);
      expect(tracker.canGoBack, isTrue);

      final backToA = tracker.goBack();
      expect(backToA?.id, 'view-a');
      expect(tracker.canGoBack, isFalse);
    });

    test('preserves navigation arguments and distinguishes argument changes', () {
      final tracker = PageHistoryTracker();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');

      tracker.recordHistory(viewA, arguments: {'blockId': 'block-1'});
      tracker.recordHistory(viewA, arguments: {'blockId': 'block-1'});
      expect(tracker.canGoBack, isFalse);

      tracker.recordHistory(viewA, arguments: {'blockId': 'block-2'});
      expect(tracker.canGoBack, isTrue);

      final backEntry = tracker.goBackEntry();
      expect(backEntry?.view.id, 'view-a');
      expect(backEntry?.arguments, {'blockId': 'block-1'});

      final forwardEntry = tracker.goForwardEntry();
      expect(forwardEntry?.arguments, {'blockId': 'block-2'});
    });

    test('bounds history length to maxEntries and keeps index valid', () {
      final tracker = PageHistoryTracker(maxEntries: 3);
      tracker.recordHistory(ViewPB(id: 'v1', name: '1'));
      tracker.recordHistory(ViewPB(id: 'v2', name: '2'));
      tracker.recordHistory(ViewPB(id: 'v3', name: '3'));
      tracker.recordHistory(ViewPB(id: 'v4', name: '4'));

      expect(tracker.history.map((v) => v.id).toList(), ['v2', 'v3', 'v4']);
      expect(tracker.historyIndex, 2);
      expect(tracker.goBack()?.id, 'v3');
      expect(tracker.goBack()?.id, 'v2');
      expect(tracker.canGoBack, isFalse);
    });

    test('removeView prunes deleted views and collapses adjacent duplicates', () {
      final tracker = PageHistoryTracker();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');
      final viewB = ViewPB(id: 'view-b', name: 'Page B');
      final viewC = ViewPB(id: 'view-c', name: 'Page C');

      tracker.recordHistory(viewA);
      tracker.recordHistory(viewB);
      tracker.recordHistory(viewA);
      tracker.recordHistory(viewC);

      tracker.removeView('view-b');
      expect(tracker.history.map((v) => v.id).toList(), ['view-a', 'view-c']);
      expect(tracker.historyIndex, 1);
      expect(tracker.goBack()?.id, 'view-a');
      expect(tracker.canGoBack, isFalse);

      tracker.removeView('view-a');
      expect(tracker.history.map((v) => v.id).toList(), ['view-c']);
      expect(tracker.historyIndex, 0);

      tracker.removeView('view-c');
      expect(tracker.history, isEmpty);
      expect(tracker.historyIndex, -1);
      expect(tracker.canGoBack, isFalse);
      expect(tracker.canGoForward, isFalse);
    });

    test('clear resets history and index', () {
      final tracker = PageHistoryTracker();
      tracker.recordHistory(ViewPB(id: 'view-a', name: 'Page A'));
      tracker.recordHistory(ViewPB(id: 'view-b', name: 'Page B'));

      tracker.clear();
      expect(tracker.history, isEmpty);
      expect(tracker.historyIndex, -1);
      expect(tracker.canGoBack, isFalse);
      expect(tracker.canGoForward, isFalse);
    });
  });
}
