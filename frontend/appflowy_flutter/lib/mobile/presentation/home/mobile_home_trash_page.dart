import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/trash/application/prelude.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileHomeTrashPage extends StatelessWidget {
  static const routeName = '/trash';

  const MobileHomeTrashPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrashBloc>()..add(const TrashEvent.initial()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(LocaleKeys.trash_text.tr()),
              elevation: 0,
              actions: [
                IconButton(
                  splashRadius: 20,
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    final trashBloc = context.read<TrashBloc>();
                    showMobileBottomSheet(
                      context: context,
                      builder: (_) => BlocProvider<TrashBloc>.value(
                        value: trashBloc,
                        child: BlocBuilder<TrashBloc, TrashState>(
                          builder: (context, state) {
                            return const MobileViewItemBottomSheet(
                              defaultType: MobileBottomSheetType.trash,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: BlocBuilder<TrashBloc, TrashState>(
              builder: (_, state) {
                if (state.objects.isEmpty) {
                  return const _TrashEmptyPage();
                }
                return _DeletedFilesListView(state);
              },
            ),
          );
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
    return ListView.builder(
      itemBuilder: (context, index) {
        final object = state.objects[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            // TODO(Yijing): implement file type after TrashPB has file type
            leading: FlowySvg(
              FlowySvgs.documents_s,
              size: const Size.square(24),
              color: theme.colorScheme.onSurface,
            ),
            title: Text(
              object.name,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onBackground),
            ),
            horizontalTitleGap: 0,
            // TODO(yiing): needs improve by container/surface theme color
            tileColor: theme.colorScheme.onSurface.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TODO(yijing): extract icon button
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
                        .add(TrashEvent.putback(object.id));
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
                    context.read<TrashBloc>().add(TrashEvent.delete(object));
                  },
                )
              ],
            ),
          ),
        );
      },
      itemCount: state.objects.length,
    );
  }
}

class _TrashEmptyPage extends StatelessWidget {
  const _TrashEmptyPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🗑️',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.trash_mobile_empty.tr(),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.trash_mobile_emptyDescription.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
