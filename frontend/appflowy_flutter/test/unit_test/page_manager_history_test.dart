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
  });
}
