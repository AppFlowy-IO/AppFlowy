import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SheetPage {
  const SheetPage({
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;
}

void showPaginatedBottomSheet(BuildContext context, {required SheetPage page}) {
  showMobileBottomSheet(
    context,
    // Workaround for not causing drag to rebuild
    isDragEnabled: false,
    builder: (context) => FlowyBottomSheet(root: page),
  );
}

typedef SheetNotifier = ValueNotifier<(SheetPage, bool)>;

class FlowyBottomSheet extends StatelessWidget {
  FlowyBottomSheet({
    super.key,
    required this.root,
  }) : _notifier = ValueNotifier((root, true));

  final SheetPage root;
  final SheetNotifier _notifier;

  @override
  Widget build(BuildContext context) {
    return FlowyBottomSheetController(
      key: UniqueKey(),
      root: root,
      onPageChanged: (page, isRoot) => _notifier.value = (page, isRoot),
      child: _FlowyBottomSheetHandler(
        root: root,
        notifier: _notifier,
      ),
    );
  }
}

class _FlowyBottomSheetHandler extends StatefulWidget {
  const _FlowyBottomSheetHandler({
    required this.root,
    required this.notifier,
  });

  final SheetPage root;
  final ValueNotifier<(SheetPage, bool)> notifier;

  @override
  State<_FlowyBottomSheetHandler> createState() =>
      _FlowyBottomSheetHandlerState();
}

class _FlowyBottomSheetHandlerState extends State<_FlowyBottomSheetHandler> {
  late SheetPage currentPage;
  late bool isRoot;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onPageChanged);
    isRoot = true;
    currentPage = widget.root;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentPage = FlowyBottomSheetController.of(context)!.currentPage;
    });
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    final (page, root) = widget.notifier.value;

    if (mounted) {
      setState(() {
        currentPage = page;
        isRoot = root;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      child: FlowyBottomSheetPage(
        isRoot: isRoot,
        title: currentPage.title,
        child: currentPage.body,
      ),
    );
  }
}

class FlowyBottomSheetPage extends StatelessWidget {
  const FlowyBottomSheetPage({
    super.key,
    required this.title,
    required this.child,
    this.isRoot = false,
  });

  final String title;
  final Widget child;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetTopBar(title: title, isRoot: isRoot),
        child,
      ],
    );
  }
}

class _SheetTopBar extends StatelessWidget {
  const _SheetTopBar({
    required this.title,
    this.isRoot = false,
  });

  final String title;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (!isRoot) ...[
          IconButton(
            onPressed: () => FlowyBottomSheetController.of(context)!.pop(),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const HSpace(6),
        ],
        Text(
          title,
          style: theme.textTheme.labelSmall,
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            Icons.close,
            color: theme.hintColor,
          ),
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

class FlowyBottomSheetController extends InheritedWidget {
  FlowyBottomSheetController({
    super.key,
    required SheetPage root,
    this.onPageChanged,
    required super.child,
    FlowyBottomSheetControllerImpl? controller,
  }) : _controller = controller ?? FlowyBottomSheetControllerImpl(root: root);

  final Function(SheetPage page, bool isRoot)? onPageChanged;

  final FlowyBottomSheetControllerImpl _controller;
  SheetPage get currentPage => _controller.page;

  @override
  bool updateShouldNotify(covariant FlowyBottomSheetController oldWidget) {
    return child != oldWidget.child ||
        _controller.length != oldWidget._controller.length;
  }

  static FlowyBottomSheetController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlowyBottomSheetController>();
  }

  void push(SheetPage page) {
    _controller.push(page);
    onPageChanged?.call(_controller.page, _controller.isRoot);
  }

  void pop() {
    _controller.pop();
    onPageChanged?.call(_controller.page, _controller.isRoot);
  }
}

class FlowyBottomSheetControllerImpl {
  FlowyBottomSheetControllerImpl({
    required SheetPage root,
  }) : _pages = [root];

  final List<SheetPage> _pages;
  SheetPage get page => _pages.last;
  bool get isRoot => _pages.length == 1;

  int get length => _pages.length;

  void push(SheetPage page) {
    _pages.add(page);
  }

  void pop() {
    _pages.remove(page);
  }
}
