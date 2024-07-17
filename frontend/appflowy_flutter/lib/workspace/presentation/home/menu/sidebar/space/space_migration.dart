import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpaceMigration extends StatelessWidget {
  const SpaceMigration({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpaceHintButton(
      collapsedTitle: LocaleKeys.space_upgradeYourSpace.tr(),
      expandedTitle: LocaleKeys.space_upgradeSpaceTitle.tr(),
      expandedDescription: LocaleKeys.space_upgradeSpaceDescription.tr(),
      expandedButtonLabel: LocaleKeys.space_upgrade.tr(),
      onClick: () => context.read<SpaceBloc>().add(
            const SpaceEvent.migrate(),
          ),
    );
  }
}
