import 'package:appflowy/ai/service/view_selector_cubit.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ViewPB testView(
    String id,
    String name,
    ViewLayoutPB layout, [
    bool isSpace = false,
    List<ViewPB> children = const [],
  ]) {
    return ViewPB()
      ..id = id
      ..name = name
      ..layout = layout
      ..isSpace = isSpace
      ..childViews.addAll(children);
  }

  List<ViewPB> createTestViews() {
    return [
      testView('1', 'View 1', ViewLayoutPB.Document, true, [
        testView('1-1', 'View 1-1', ViewLayoutPB.Document),
        testView('1-2', 'View 1-2', ViewLayoutPB.Document),
      ]),
      testView('2', 'View 2', ViewLayoutPB.Document, false, [
        testView('2-1', 'View 2-1', ViewLayoutPB.Document),
        testView('2-2', 'View 2-2', ViewLayoutPB.Grid),
        testView('2-3', 'View 2-3', ViewLayoutPB.Document, false, [
          testView('2-3-1', 'View 2-3-1', ViewLayoutPB.Document),
        ]),
      ]),
      testView('3', 'View 3', ViewLayoutPB.Document, true, [
        testView('3-1', 'View 3-1', ViewLayoutPB.Grid, false, [
          testView('3-1-1', 'View 3-1-1', ViewLayoutPB.Board),
        ]),
      ]),
      testView('4', 'View 4', ViewLayoutPB.Document, true, [
        testView('4-1', 'View 4-1', ViewLayoutPB.Chat),
        testView('4-2', 'View 4-2', ViewLayoutPB.Document, false, [
          testView('4-2-1', 'View 4-2-1', ViewLayoutPB.Document),
          testView('4-2-2', 'View 4-2-2', ViewLayoutPB.Document),
        ]),
      ]),
    ];
  }

  Map<String, ViewSelectedStatus> getSelectedStatus(
    List<ViewSelectorItem> items,
  ) {
    return {
      for (final item in items) item.view.id: item.selectedStatus,
      for (final item in items)
        if (item.children.isNotEmpty) ...getSelectedStatus(item.children),
    };
  }

  group('ViewSelectorCubit test:', () {
    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'initial state',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 1,
      ),
      act: (_) {},
      verify: (cubit) {
        final s = cubit.state;
        expect(s.visibleSources, isEmpty);
        expect(s.selectedSources, isEmpty);
      },
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'update sources',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 1,
      ),
      act: (cubit) async {
        final views = createTestViews();
        await cubit.refreshSources(views, views.first);
      },
      verify: (cubit) {
        final s = cubit.state;
        expect(s.visibleSources.length, 4);
        expect(s.visibleSources[0].isExpanded, isTrue);
        expect(s.visibleSources[0].children.length, 2);
        expect(s.visibleSources[1].children.length, 3);
        expect(s.visibleSources[2].children.length, 1);
        expect(s.visibleSources[3].children.length, 2);
        expect(s.selectedSources.isEmpty, isTrue);
      },
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'update sources multiple times',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 1,
      ),
      act: (cubit) async {
        final views = createTestViews();
        await cubit.refreshSources([], null);
        await cubit.refreshSources(views, null);
        await cubit.refreshSources([], null);
      },
      expect: () => [
        predicate<ViewSelectorState>(
          (s) => s.visibleSources.isEmpty && s.selectedSources.isEmpty,
        ),
        predicate<ViewSelectorState>(
          (s) => s.visibleSources.isNotEmpty && s.selectedSources.isEmpty,
        ),
        predicate<ViewSelectorState>(
          (s) => s.visibleSources.isEmpty && s.selectedSources.isEmpty,
        ),
      ],
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'update selected sources',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 100,
      ),
      act: (cubit) async {
        final views = createTestViews();
        cubit.updateSelectedSources([
          '2-3-1',
          '3-1',
          '3-1-1',
          '4-2',
          '4-2-1',
        ]);
        await cubit.refreshSources(views, null);
      },
      skip: 1,
      expect: () => [
        predicate<ViewSelectorState>((s) {
          final lengthCheck =
              s.visibleSources.length == 4 && s.selectedSources.length == 3;

          final expected = {
            '1': ViewSelectedStatus.unselected,
            '1-1': ViewSelectedStatus.unselected,
            '1-2': ViewSelectedStatus.unselected,
            '2': ViewSelectedStatus.partiallySelected,
            '2-1': ViewSelectedStatus.unselected,
            '2-2': ViewSelectedStatus.unselected,
            '2-3': ViewSelectedStatus.partiallySelected,
            '2-3-1': ViewSelectedStatus.selected,
            '3': ViewSelectedStatus.partiallySelected,
            '3-1': ViewSelectedStatus.selected,
            '3-1-1': ViewSelectedStatus.selected,
            '4': ViewSelectedStatus.partiallySelected,
            '4-1': ViewSelectedStatus.unselected,
            '4-2': ViewSelectedStatus.partiallySelected,
            '4-2-1': ViewSelectedStatus.selected,
            '4-2-2': ViewSelectedStatus.unselected,
          };

          final actual = getSelectedStatus(s.visibleSources);

          return lengthCheck && mapEquals(expected, actual);
        }),
      ],
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'select a source 1',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 100,
      ),
      act: (cubit) async {
        final views = createTestViews();
        await cubit.refreshSources(views, null);
        cubit.toggleSelectedStatus(
          cubit.state.visibleSources[1].children[2].children[0], // '2-3-1',
          false,
        );
      },
      skip: 1,
      expect: () => [
        predicate<ViewSelectorState>((s) {
          return getSelectedStatus(s.visibleSources)
              .values
              .every((value) => value == ViewSelectedStatus.unselected);
        }),
        predicate<ViewSelectorState>((s) {
          final selectedStatusMap = getSelectedStatus(s.visibleSources);
          return selectedStatusMap['2-3'] ==
                  ViewSelectedStatus.partiallySelected &&
              selectedStatusMap['2-3-1'] == ViewSelectedStatus.selected;
        }),
      ],
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'select a source 2',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 100,
      ),
      act: (cubit) async {
        final views = createTestViews();
        await cubit.refreshSources(views, null);
        cubit.toggleSelectedStatus(
          cubit.state.visibleSources[1].children[2], // '2-3',
          false,
        );
        cubit.toggleSelectedStatus(
          cubit.state.visibleSources[1].children[2].children[0], // '2-3-1',
          false,
        );
      },
      skip: 2,
      expect: () => [
        predicate<ViewSelectorState>((s) {
          final selectedStatusMap = getSelectedStatus(s.visibleSources);
          return selectedStatusMap['2-3'] == ViewSelectedStatus.selected &&
              selectedStatusMap['2-3-1'] == ViewSelectedStatus.selected;
        }),
        predicate<ViewSelectorState>((s) {
          final selectedStatusMap = getSelectedStatus(s.visibleSources);
          return selectedStatusMap['2-3'] ==
                  ViewSelectedStatus.partiallySelected &&
              selectedStatusMap['2-3-1'] == ViewSelectedStatus.unselected;
        }),
      ],
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'select a source 3',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 100,
      ),
      act: (cubit) async {
        final views = createTestViews();
        cubit.updateSelectedSources(['2-3', '2-3-1']);
        await cubit.refreshSources(views, null);
        cubit.toggleSelectedStatus(
          cubit.state.visibleSources[1].children[2], // '2-3',
          false,
        );
      },
      skip: 1,
      expect: () => [
        predicate<ViewSelectorState>((s) {
          final selectedStatusMap = getSelectedStatus(s.visibleSources);
          return selectedStatusMap['2-3'] == ViewSelectedStatus.selected &&
              selectedStatusMap['2-3-1'] == ViewSelectedStatus.selected;
        }),
        predicate<ViewSelectorState>((s) {
          final selectedStatusMap = getSelectedStatus(s.visibleSources);
          return selectedStatusMap['2-3'] == ViewSelectedStatus.unselected &&
              selectedStatusMap['2-3-1'] == ViewSelectedStatus.unselected;
        }),
      ],
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'select a source 4',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 100,
      ),
      act: (cubit) async {
        final views = createTestViews();
        cubit.updateSelectedSources(['4-2', '4-2-1']);
        await cubit.refreshSources(views, null);
        cubit.toggleSelectedStatus(
          cubit.state.visibleSources[3].children[1].children[1], // 4-2-2,
          false,
        );
      },
      skip: 1,
      expect: () => [
        predicate<ViewSelectorState>((s) {
          final selectedStatusMap = getSelectedStatus(s.visibleSources);
          return selectedStatusMap['4-2'] ==
                  ViewSelectedStatus.partiallySelected &&
              selectedStatusMap['4-2-1'] == ViewSelectedStatus.selected &&
              selectedStatusMap['4-2-2'] == ViewSelectedStatus.unselected;
        }),
        predicate<ViewSelectorState>((s) {
          final selectedStatusMap = getSelectedStatus(s.visibleSources);
          return selectedStatusMap['4-2'] == ViewSelectedStatus.selected &&
              selectedStatusMap['4-2-1'] == ViewSelectedStatus.selected &&
              selectedStatusMap['4-2-2'] == ViewSelectedStatus.selected;
        }),
      ],
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'select a source 5',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 100,
      ),
      act: (cubit) async {
        final views = createTestViews();
        cubit.updateSelectedSources(['4-2', '4-2-1']);
        await cubit.refreshSources(views, null);
        cubit.toggleSelectedStatus(
          cubit.state.visibleSources[3].children[1], // 4-2
          false,
        );
      },
      verify: (cubit) {
        final selectedStatusMap = getSelectedStatus(cubit.state.visibleSources);
        expect(selectedStatusMap['4-2'], ViewSelectedStatus.unselected);
        expect(selectedStatusMap['4-2-1'], ViewSelectedStatus.unselected);
        expect(selectedStatusMap['4-2-2'], ViewSelectedStatus.unselected);
      },
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'cannot select more than maximum selection limit',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 2,
      ),
      act: (cubit) async {
        final views = createTestViews();
        cubit.updateSelectedSources(['1-1', '2-1']);
        await cubit.refreshSources(views, null);
      },
      verify: (cubit) {
        final s = cubit.state;
        expect(s.visibleSources[0].children[0].isDisabled, isFalse);
        expect(s.visibleSources[0].children[1].isDisabled, isFalse);
        expect(s.visibleSources[1].children[0].isDisabled, isFalse);
        expect(s.visibleSources[1].children[1].isDisabled, isFalse);
        expect(s.visibleSources[2].children[0].isDisabled, isTrue);
      },
    );

    blocTest<ViewSelectorCubit, ViewSelectorState>(
      'filter sources correctly',
      build: () => ViewSelectorCubit(
        getIgnoreViewType: (_) => IgnoreViewType.none,
        maxSelectedParentPageCount: 1,
      ),
      act: (cubit) async {
        final views = createTestViews();
        await cubit.refreshSources(views, null);
        cubit.filterTextController.text = 'View 1';
      },
      verify: (cubit) {
        final s = cubit.state;
        expect(s.visibleSources.length, 1);
        expect(s.visibleSources[0].children.length, 2);
      },
    );
  });
}
