import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/trash/src/sizes.dart';
import 'package:appflowy/plugins/trash/src/trash_header.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import 'application/trash_bloc.dart';
import 'src/trash_cell.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 80.0;
    return BlocProvider(
      create: (context) => getIt<TrashBloc>()..add(const TrashEvent.initial()),
      child: BlocBuilder<TrashBloc, TrashState>(
        builder: (context, state) {
          return SizedBox.expand(
            child: Column(
              children: [
                _renderTopBar(context, state),
                const VSpace(32),
                _renderTrashList(context, state),
              ],
            ).padding(horizontal: horizontalPadding, vertical: 48),
          );
        },
      ),
    );
  }

  Widget _renderTrashList(BuildContext context, TrashState state) {
    const barSize = 6.0;
    return Expanded(
      child: ScrollbarListStack(
        axis: Axis.vertical,
        controller: _scrollController,
        scrollbarPadding: EdgeInsets.only(top: TrashSizes.headerHeight),
        barSize: barSize,
        child: StyledSingleChildScrollView(
          barSize: barSize,
          axis: Axis.horizontal,
          child: SizedBox(
            width: TrashSizes.totalWidth,
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: CustomScrollView(
                shrinkWrap: true,
                physics: StyledScrollPhysics(),
                controller: _scrollController,
                slivers: [
                  _renderListHeader(context, state),
                  _renderListBody(context, state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderTopBar(BuildContext context, TrashState state) {
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowyText.semibold(
            LocaleKeys.trash_text.tr(),
            fontSize: FontSizes.s16,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const Spacer(),
          IntrinsicWidth(
            child: FlowyButton(
              text: FlowyText.medium(
                LocaleKeys.trash_restoreAll.tr(),
                lineHeight: 1.0,
              ),
              leftIcon: const FlowySvg(FlowySvgs.restore_s),
              onTap: () => showCancelAndConfirmDialog(
                context: context,
                confirmLabel: LocaleKeys.trash_restore.tr(),
                title: LocaleKeys.trash_confirmRestoreAll_title.tr(),
                description: LocaleKeys.trash_confirmRestoreAll_caption.tr(),
                onConfirm: () => context
                    .read<TrashBloc>()
                    .add(const TrashEvent.restoreAll()),
              ),
            ),
          ),
          const HSpace(6),
          IntrinsicWidth(
            child: FlowyButton(
              text: FlowyText.medium(
                LocaleKeys.trash_deleteAll.tr(),
                lineHeight: 1.0,
              ),
              leftIcon: const FlowySvg(FlowySvgs.delete_s),
              onTap: () => showConfirmDeletionDialog(
                context: context,
                name: LocaleKeys.trash_confirmDeleteAll_title.tr(),
                description: LocaleKeys.trash_confirmDeleteAll_caption.tr(),
                onConfirm: () =>
                    context.read<TrashBloc>().add(const TrashEvent.deleteAll()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderListHeader(BuildContext context, TrashState state) {
    return SliverPersistentHeader(
      delegate: TrashHeaderDelegate(),
      floating: true,
      pinned: true,
    );
  }

  Widget _renderListBody(BuildContext context, TrashState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final object = state.objects[index];
          return SizedBox(
            height: 42,
            child: TrashCell(
              object: object,
              onRestore: () => showCancelAndConfirmDialog(
                context: context,
                title: object.name,
                description: LocaleKeys.trash_restorePage_caption.tr(),
                onConfirm: () => context
                    .read<TrashBloc>()
                    .add(TrashEvent.putback(object.id)),
              ),
              onDelete: () => showConfirmDeletionDialog(
                context: context,
                name: object.name,
                description: LocaleKeys.deletePagePrompt_deletePermanent.tr(),
                onConfirm: () =>
                    context.read<TrashBloc>().add(TrashEvent.delete(object)),
              ),
            ),
          );
        },
        childCount: state.objects.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }
}
