import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/language.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsLanguageView extends StatelessWidget {
  const SettingsLanguageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        builder: (context, state) => Row(
          children: [
            Expanded(
              child: FlowyText.medium(
                LocaleKeys.settings_menu_language.tr(),
              ),
            ),
            LanguageSelector(currentLocale: state.locale),
          ],
        ),
      ),
    );
  }
}

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  const LanguageSelector({
    super.key,
    required this.currentLocale,
  });

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

        return LanguageItemsListView(
          allLocales: allLocales,
          currentLocale: currentLocale,
        );
      },
    );
  }
}

class LanguageItemsListView extends StatelessWidget {
  const LanguageItemsListView({
    super.key,
    required this.allLocales,
    required this.currentLocale,
  });

  final List<Locale> allLocales;
  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        itemBuilder: (context, index) {
          final locale = allLocales[index];
          return LanguageItem(locale: locale, currentLocale: currentLocale);
        },
        itemCount: allLocales.length,
      ),
    );
  }
}

class LanguageItem extends StatelessWidget {
  final Locale locale;
  final Locale currentLocale;
  const LanguageItem({
    super.key,
    required this.locale,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(
          languageFromLocale(locale),
        ),
        rightIcon: currentLocale == locale
            ? const FlowySvg(name: 'grid/checkmark')
            : null,
        onTap: () {
          if (currentLocale != locale) {
            context.read<AppearanceSettingsCubit>().setLocale(context, locale);
          }
        },
      ),
    );
  }
}
