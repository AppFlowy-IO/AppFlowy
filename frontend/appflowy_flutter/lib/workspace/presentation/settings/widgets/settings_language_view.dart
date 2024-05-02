import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsLanguageView extends StatelessWidget {
  const SettingsLanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) => SettingsBody(
        children: [
          SettingsHeader(title: LocaleKeys.settings_menu_language.tr()),
          Row(
            children: [
              Expanded(
                child: FlowyText.medium(
                  LocaleKeys.settings_menu_language.tr(),
                ),
              ),
              LanguageSelector(currentLocale: state.locale),
            ],
          ),
        ],
      ),
    );
  }
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, required this.currentLocale});

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithRightAligned,
      child: FlowyTextButton(
        languageFromLocale(currentLocale),
        fontColor: Theme.of(context).colorScheme.onBackground,
        fillColor: Colors.transparent,
        onPressed: () {},
      ),
      popupBuilder: (BuildContext context) {
        final allLocales = EasyLocalization.of(context)!.supportedLocales;
        return LanguageItemsListView(allLocales: allLocales);
      },
    );
  }
}

class LanguageItemsListView extends StatelessWidget {
  const LanguageItemsListView({
    super.key,
    required this.allLocales,
  });

  final List<Locale> allLocales;

  @override
  Widget build(BuildContext context) {
    // get current locale from cubit
    final state = context.watch<AppearanceSettingsCubit>().state;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        itemBuilder: (context, index) {
          final locale = allLocales[index];
          return LanguageItem(
            locale: locale,
            currentLocale: state.locale,
          );
        },
        itemCount: allLocales.length,
      ),
    );
  }
}

class LanguageItem extends StatelessWidget {
  const LanguageItem({
    super.key,
    required this.locale,
    required this.currentLocale,
  });

  final Locale locale;
  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(
          languageFromLocale(locale),
        ),
        rightIcon:
            currentLocale == locale ? const FlowySvg(FlowySvgs.check_s) : null,
        onTap: () {
          if (currentLocale != locale) {
            context.read<AppearanceSettingsCubit>().setLocale(context, locale);
          }
          PopoverContainer.of(context).close();
        },
      ),
    );
  }
}
