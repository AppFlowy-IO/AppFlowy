import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/trash/application/prelude.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

class MobileHomeTrashPage extends StatelessWidget {
  const MobileHomeTrashPage({super.key});

  static const routeName = '/trash';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrashBloc>()..add(const TrashEvent.initial()),
      child: BlocBuilder<TrashBloc, TrashState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(LocaleKeys.trash_text.tr()),
              actions: [
                state.objects.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        splashRadius: 20,
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {
                          final trashBloc = context.read<TrashBloc>();
                          showMobileBottomSheet(
                            context,
                            showHeader: true,
                            showCloseButton: true,
                            showDragHandle: true,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            title: LocaleKeys.trash_mobile_actions.tr(),
                            builder: (_) => Row(
                              children: [
                                Expanded(
                                  child: _TrashActionAllButton(
                                    trashBloc: trashBloc,
                                  ),
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: _TrashActionAllButton(
                                    trashBloc: trashBloc,
                                    type: _TrashActionType.restoreAll,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
            body: state.objects.isEmpty
                ? FlowyMobileStateContainer.info(
                    emoji: '🗑️',
                    title: LocaleKeys.trash_mobile_empty.tr(),
                    description: LocaleKeys.trash_mobile_emptyDescription.tr(),
                  )
                : _DeletedFilesListView(state),
          );
        },
      ),
    );
  }
}

enum _TrashActionType {
  restoreAll,
  deleteAll,
}

class _TrashActionAllButton extends StatelessWidget {
  /// Switch between 'delete all' and 'restore all' feature
  const _TrashActionAllButton({
    this.type = _TrashActionType.deleteAll,
    required this.trashBloc,
  });
  final _TrashActionType type;
  final TrashBloc trashBloc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeleteAll = type == _TrashActionType.deleteAll;
    return BlocProvider.value(
      value: trashBloc,
      child: BottomSheetActionWidget(
        svg: isDeleteAll ? FlowySvgs.m_delete_m : FlowySvgs.m_restore_m,
        text: isDeleteAll
            ? LocaleKeys.trash_deleteAll.tr()
            : LocaleKeys.trash_restoreAll.tr(),
        onTap: () {
          final trashList = trashBloc.state.objects;
          if (trashList.isNotEmpty) {
            context.pop();
            showFlowyMobileConfirmDialog(
              context,
              title: FlowyText(
                isDeleteAll
                    ? LocaleKeys.trash_confirmDeleteAll_title.tr()
                    : LocaleKeys.trash_restoreAll.tr(),
              ),
              content: FlowyText(
                isDeleteAll
                    ? LocaleKeys.trash_confirmDeleteAll_caption.tr()
                    : LocaleKeys.trash_confirmRestoreAll_caption.tr(),
              ),
              actionButtonTitle: isDeleteAll
                  ? LocaleKeys.trash_deleteAll.tr()
                  : LocaleKeys.trash_restoreAll.tr(),
              actionButtonColor: isDeleteAll
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              onActionButtonPressed: () {
                if (isDeleteAll) {
                  trashBloc.add(
                    const TrashEvent.deleteAll(),
                  );
                } else {
                  trashBloc.add(
                    const TrashEvent.restoreAll(),
                  );
                }
              },
              cancelButtonTitle: LocaleKeys.button_cancel.tr(),
            );
          } else {
            // when there is no deleted files
            // show toast
            Fluttertoast.showToast(
              msg: LocaleKeys.trash_mobile_empty.tr(),
              gravity: ToastGravity.CENTER,
            );
          }
        },
      ),
    );
  }
}

class _DeletedFilesListView extends StatelessWidget {
  const _DeletedFilesListView(
    this.state,
  );

  final TrashState state;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        itemBuilder: (context, index) {
          final deletedFile = state.objects[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              // TODO: show different file type icon, implement this feature after TrashPB has file type field
              leading: FlowySvg(
                FlowySvgs.document_s,
                size: const Size.square(24),
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                deletedFile.name,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurface),
              ),
              horizontalTitleGap: 0,
              tileColor: theme.colorScheme.onSurface.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    splashRadius: 20,
                    icon: FlowySvg(
                      FlowySvgs.m_restore_m,
                      size: const Size.square(24),
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      context
                          .read<TrashBloc>()
                          .add(TrashEvent.putback(deletedFile.id));
                      Fluttertoast.showToast(
                        msg:
                            '${deletedFile.name} ${LocaleKeys.trash_mobile_isRestored.tr()}',
                        gravity: ToastGravity.BOTTOM,
                      );
                    },
                  ),
                  IconButton(
                    splashRadius: 20,
                    icon: FlowySvg(
                      FlowySvgs.m_delete_m,
                      size: const Size.square(24),
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      context
                          .read<TrashBloc>()
                          .add(TrashEvent.delete(deletedFile));
                      Fluttertoast.showToast(
                        msg:
                            '${deletedFile.name} ${LocaleKeys.trash_mobile_isDeleted.tr()}',
                        gravity: ToastGravity.BOTTOM,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        itemCount: state.objects.length,
      ),
    );
  }
}
