import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class BuiltInPageWidget extends StatefulWidget {
  const BuiltInPageWidget({
    super.key,
    required this.node,
    required this.editorState,
    required this.builder,
  });

  final Node node;
  final EditorState editorState;
  final Widget Function(ViewPB viewPB) builder;

  @override
  State<BuiltInPageWidget> createState() => _BuiltInPageWidgetState();
}

class _BuiltInPageWidgetState extends State<BuiltInPageWidget> {
  late Future<FlowyResult<ViewPB, FlowyError>> future;

  final focusNode = FocusNode();

  String get parentViewId => widget.node.attributes[DatabaseBlockKeys.parentID];
  String get childViewId => widget.node.attributes[DatabaseBlockKeys.viewID];

  @override
  void initState() {
    super.initState();
    future = ViewBackendService().getChildView(
      parentViewId: parentViewId,
      childViewId: childViewId,
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlowyResult<ViewPB, FlowyError>>(
      builder: (context, snapshot) {
        final page = snapshot.data?.toNullable();
        if (snapshot.hasData && page != null) {
          return _build(context, page);
        }
        if (snapshot.connectionState == ConnectionState.done) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            // just delete the page if it is not found
            _deletePage();
          });
          return const Center(
            child: FlowyText('Cannot load the page'),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      future: future,
    );
  }

  Widget _build(BuildContext context, ViewPB viewPB) {
    return MouseRegion(
      onEnter: (_) => widget.editorState.service.scrollService?.disable(),
      onExit: (_) => widget.editorState.service.scrollService?.enable(),
      child: SizedBox(
        height: viewPB.pluginType == PluginType.calendar ? 700 : 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenu(context, viewPB),
            Expanded(child: _buildPage(context, viewPB)),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, ViewPB viewPB) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (value) {
        if (value) {
          widget.editorState.service.selectionService.clearSelection();
        }
      },
      child: widget.builder(viewPB),
    );
  }

  Widget _buildMenu(BuildContext context, ViewPB viewPB) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // information
        FlowyIconButton(
          tooltipText: LocaleKeys.tooltip_referencePage.tr(
            namedArgs: {'name': viewPB.layout.name},
          ),
          width: 24,
          height: 24,
          iconPadding: const EdgeInsets.all(3),
          icon: const FlowySvg(
            FlowySvgs.information_s,
          ),
          iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
        ),
        // setting
        const Space(7, 0),
        PopoverActionList<_ActionWrapper>(
          direction: PopoverDirection.bottomWithCenterAligned,
          actions: _ActionType.values
              .map((action) => _ActionWrapper(action))
              .toList(),
          buildChild: (controller) => FlowyIconButton(
            tooltipText: LocaleKeys.tooltip_openMenu.tr(),
            width: 24,
            height: 24,
            iconPadding: const EdgeInsets.all(3),
            iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
            icon: const FlowySvg(
              FlowySvgs.settings_s,
            ),
            onPressed: () => controller.show(),
          ),
          onSelected: (action, controller) async {
            switch (action.inner) {
              case _ActionType.viewDatabase:
                getIt<TabsBloc>().add(
                  TabsEvent.openPlugin(
                    plugin: viewPB.plugin(),
                    view: viewPB,
                  ),
                );
                break;
              case _ActionType.delete:
                final transaction = widget.editorState.transaction;
                transaction.deleteNode(widget.node);
                await widget.editorState.apply(transaction);
                break;
            }
            controller.close();
          },
        ),
      ],
    );
  }

  Future<void> _deletePage() async {
    final transaction = widget.editorState.transaction;
    transaction.deleteNode(widget.node);
    await widget.editorState.apply(transaction);
  }
}

enum _ActionType {
  viewDatabase,
  delete,
}

class _ActionWrapper extends ActionCell {
  _ActionWrapper(this.inner);

  final _ActionType inner;

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    switch (inner) {
      case _ActionType.viewDatabase:
        return LocaleKeys.tooltip_viewDataBase.tr();
      case _ActionType.delete:
        return LocaleKeys.disclosureAction_delete.tr();
    }
  }
}
