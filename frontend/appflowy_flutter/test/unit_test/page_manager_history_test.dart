import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageManager history navigation', () {
    test('initial state has no history', () {
      final pageManager = PageManager();
      expect(pageManager.canGoBack, isFalse);
      expect(pageManager.canGoForward, isFalse);
      expect(pageManager.goBack(), isNull);
      expect(pageManager.goForward(), isNull);
    });

    test('recording single view cannot go back or forward', () {
      final pageManager = PageManager();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');

      pageManager.recordHistory(viewA);
      expect(pageManager.canGoBack, isFalse);
      expect(pageManager.canGoForward, isFalse);
    });

    test('navigates back and forward across multiple views', () {
      final pageManager = PageManager();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');
      final viewB = ViewPB(id: 'view-b', name: 'Page B');
      final viewC = ViewPB(id: 'view-c', name: 'Page C');

      pageManager.recordHistory(viewA);
      pageManager.recordHistory(viewB);
      pageManager.recordHistory(viewC);

      expect(pageManager.canGoBack, isTrue);
      expect(pageManager.canGoForward, isFalse);

      final backToB = pageManager.goBack();
      expect(backToB?.id, 'view-b');
      expect(pageManager.canGoBack, isTrue);
      expect(pageManager.canGoForward, isTrue);

      final backToA = pageManager.goBack();
      expect(backToA?.id, 'view-a');
      expect(pageManager.canGoBack, isFalse);
      expect(pageManager.canGoForward, isTrue);

      final forwardToB = pageManager.goForward();
      expect(forwardToB?.id, 'view-b');
      expect(pageManager.canGoBack, isTrue);
      expect(pageManager.canGoForward, isTrue);

      final forwardToC = pageManager.goForward();
      expect(forwardToC?.id, 'view-c');
      expect(pageManager.canGoBack, isTrue);
      expect(pageManager.canGoForward, isFalse);
    });

    test('ignores consecutive duplicate view records', () {
      final pageManager = PageManager();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');

      pageManager.recordHistory(viewA);
      pageManager.recordHistory(viewA);

      expect(pageManager.canGoBack, isFalse);
    });

    test('branching history truncates forward stack', () {
      final pageManager = PageManager();
      final viewA = ViewPB(id: 'view-a', name: 'Page A');
      final viewB = ViewPB(id: 'view-b', name: 'Page B');
      final viewC = ViewPB(id: 'view-c', name: 'Page C');

      pageManager.recordHistory(viewA);
      pageManager.recordHistory(viewB);

      pageManager.goBack(); // back to A
      expect(pageManager.canGoForward, isTrue);

      pageManager.recordHistory(viewC); // record C while at A
      expect(pageManager.canGoForward, isFalse);
      expect(pageManager.canGoBack, isTrue);

      final backToA = pageManager.goBack();
      expect(backToA?.id, 'view-a');
    });
  });
}
