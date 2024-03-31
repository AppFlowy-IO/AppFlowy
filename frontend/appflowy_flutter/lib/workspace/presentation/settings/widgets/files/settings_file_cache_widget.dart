import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/appflowy_cache_manager.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsFileCacheWidget extends StatelessWidget {
  const SettingsFileCacheWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: FlowyText.medium(
                  LocaleKeys.settings_files_clearCache.tr(),
                  fontSize: 13,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const VSpace(8),
              Opacity(
                opacity: 0.6,
                child: FlowyText(
                  LocaleKeys.settings_files_clearCacheDesc.tr(),
                  fontSize: 10,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
        const _ClearCacheButton(),
      ],
    );
  }
}

class _ClearCacheButton extends StatelessWidget {
  const _ClearCacheButton();

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      hoverColor: Theme.of(context).colorScheme.secondaryContainer,
      tooltipText: LocaleKeys.settings_files_clearCache.tr(),
      icon: FlowySvg(
        FlowySvgs.delete_s,
        size: const Size.square(18),
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        NavigatorAlertDialog(
          title: LocaleKeys.settings_files_areYouSureToClearCache.tr(),
          confirm: () async {
            await getIt<FlowyCacheManager>().clearAllCache();
            if (context.mounted) {
              showSnackBarMessage(
                context,
                LocaleKeys.settings_files_clearCacheSuccess.tr(),
              );
            }
          },
        ).show(context);
      },
    );
  }
}
