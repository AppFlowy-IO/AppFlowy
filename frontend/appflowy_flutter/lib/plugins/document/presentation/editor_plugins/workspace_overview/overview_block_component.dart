import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/application/overview_adapter/workspace_to_overview_adapter_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/icon.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OverviewBlockKeys {
  const OverviewBlockKeys._();

  static const String type = 'overview';
  static const String backgroundColor = blockComponentBackgroundColor;
}

SelectionMenuItem overviewItem = SelectionMenuItem.node(
  name: LocaleKeys.document_selectionMenu_overview.tr(),
  iconData: Icons.list_alt,
  keywords: ['overview', 'workspace overview'],
  nodeBuilder: (editorState, context) => overviewBlockNode(),
  replace: (editorState, node) => node.delta?.isEmpty ?? false,
);

Node overviewBlockNode() {
  return Node(
    type: OverviewBlockKeys.type,
  );
}

class OverviewBlockComponentBuilder extends BlockComponentBuilder {
  OverviewBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return OverviewBlockWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => node.children.isEmpty;
}

class OverviewBlockWidget extends BlockComponentStatefulWidget {
  const OverviewBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<BlockComponentStatefulWidget> createState() =>
      _OverviewBlockWidgetState();
}

class _OverviewBlockWidgetState extends State<OverviewBlockWidget>
    with
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin,
        BlockComponentBackgroundColorMixin {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  EditorState get editorState => context.read<EditorState>();

  @override
  Node get node => widget.node;

  final double leftIndentIncrementValue = 20.0;

  @override
  Widget build(BuildContext context) {
    final viewId = editorState.document.id!;
    return FutureBuilder<Either<ViewPB, FlowyError>>(
      future: ViewBackendService.getAllLevelOfViews(viewId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final view = snapshot.data!.getLeftOrNull();
          return BlocProvider<WorkspaceToOverviewAdapterBloc>(
            create: (context) => WorkspaceToOverviewAdapterBloc(view: view)
              ..add(const WorkspaceToOverviewAdapterEvent.initial()),
            child: BlocBuilder<WorkspaceToOverviewAdapterBloc,
                WorkspaceToOverviewAdapterState>(
              builder: (context, state) {
                return _buildOverviewBlock(
                  state.view,
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOverviewBlock(ViewPB view) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    const double leftIndent = 0.0;

    final children =
        _buildOverviewBlockChildren(view, textDirection, leftIndent);

    Widget child = Container(
      constraints: const BoxConstraints(
        minHeight: 40.0,
      ),
      padding: padding,
      child: children.isEmpty
          ? const SizedBox.shrink()
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                color: backgroundColor,
              ),
              child: Column(
                key: ValueKey(children.hashCode),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                textDirection: textDirection,
                children: children,
              ),
            ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      if (widget.showActions && widget.actionBuilder != null) {
        child = BlockComponentActionWrapper(
          node: widget.node,
          actionBuilder: widget.actionBuilder!,
          child: child,
        );
      }
    } else {
      child = MobileBlockActionButtons(
        node: node,
        editorState: editorState,
        child: child,
      );
    }

    return child;
  }

  List<Widget> _buildOverviewBlockChildren(
    ViewPB view,
    TextDirection textDirection,
    double leftIndent,
  ) {
    final children = <Widget>[];

    children.add(
      _buildOverviewItemWidget(
        view,
        textDirection,
        leftIndent,
      ),
    );

    for (final child in view.childViews) {
      children.addAll(
        _buildOverviewBlockChildren(
          child,
          textDirection,
          leftIndent + leftIndentIncrementValue,
        ),
      );
    }

    return children;
  }

  Widget _buildOverviewItemWidget(
    ViewPB view,
    TextDirection textDirection,
    double leftIndent,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5.0),
      width: double.infinity,
      child: OverviewItemWidget(
        id: view.id,
        text: view.name,
        textDirection: textDirection,
        leftIndent: leftIndent,
        icon: view.icon,
        defaultIcon: view.defaultIcon(),
      ),
    );
  }
}

class OverviewItemWidget extends StatelessWidget {
  const OverviewItemWidget({
    super.key,
    required this.id,
    required this.text,
    required this.textDirection,
    required this.defaultIcon,
    this.leftIndent = 0.0,
    this.icon,
  });

  final String id;

  final String text;

  final ViewIconPB? icon;

  final Widget defaultIcon;

  final TextDirection textDirection;

  final double leftIndent;

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    final textStyle = editorState.editorStyle.textStyleConfiguration;
    final style = textStyle.href.combine(textStyle.text);
    return FlowyHover(
      style: HoverStyle(hoverColor: Theme.of(context).hoverColor),
      builder: (context, onHover) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {},
          child: Row(
            textDirection: textDirection,
            children: [
              HSpace(leftIndent),
              (icon != null && icon!.value.isNotEmpty)
                  ? EmojiText(
                      emoji: icon!.value,
                      fontSize: 18.0,
                    )
                  : SizedBox.square(
                      dimension: 20.0,
                      child: defaultIcon,
                    ),
              const HSpace(8.0),
              Text(
                text,
                style: style.copyWith(
                  color: onHover
                      ? Theme.of(context).colorScheme.onSecondary
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
