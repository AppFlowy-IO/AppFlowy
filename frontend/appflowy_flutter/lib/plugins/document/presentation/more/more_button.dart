import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/more/font_size_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentMoreButton extends StatelessWidget {
  const DocumentMoreButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      color: Theme.of(context).colorScheme.surfaceVariant,
      offset: const Offset(0, 30),
      tooltip: LocaleKeys.moreAction_moreOptions.tr(),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: 1,
            enabled: false,
            child: BlocProvider.value(
              value: context.read<DocumentAppearanceCubit>(),
              child: const FontSizeSwitcher(),
            ),
          ),
        ];
      },
      child: svgWidget(
        'editor/details',
        size: const Size(18, 18),
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
