import 'package:flutter/material.dart';

import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/anon_user_bloc.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SkipLogInScreen extends StatefulWidget {
  const SkipLogInScreen({super.key});

  static const routeName = '/SkipLogInScreen';

  @override
  State<SkipLogInScreen> createState() => _SkipLogInScreenState();
}

class _SkipLogInScreenState extends State<SkipLogInScreen> {
  var _didCustomizeFolder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _SkipLoginMoveWindow(),
      body: Center(child: _renderBody(context)),
    );
  }

  Widget _renderBody(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        FlowyLogoTitle(
          title: LocaleKeys.welcomeText.tr(),
          logoSize: Size.square(PlatformExtension.isMobile ? 80 : 40),
        ),
        const VSpace(32),
        GoButton(
          onPressed: () {
            if (_didCustomizeFolder) {
              _relaunchAppAndAutoRegister();
            } else {
              _autoRegister(context);
            }
          },
        ),
        // if (Env.enableCustomCloud) ...[
        //   const VSpace(10),
        //   const SizedBox(
        //     width: 340,
        //     child: _SetupYourServer(),
        //   ),
        // ],
        const VSpace(32),
        SizedBox(
          width: size.width * 0.7,
          child: FolderWidget(
            createFolderCallback: () async => _didCustomizeFolder = true,
          ),
        ),
        const Spacer(),
        const SkipLoginPageFooter(),
        const VSpace(20),
      ],
    );
  }

  Future<void> _autoRegister(BuildContext context) async {
    final result = await getIt<AuthService>().signUpAsGuest();
    result.fold(
      (user) => getIt<AuthRouter>().goHomeScreen(context, user),
      (error) => Log.error(error),
    );
  }

  Future<void> _relaunchAppAndAutoRegister() async => runAppFlowy(isAnon: true);
}

class SkipLoginPageFooter extends StatelessWidget {
  const SkipLoginPageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // The placeholderWidth should be greater than the longest width of the LanguageSelectorOnWelcomePage
    const double placeholderWidth = 180;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!PlatformExtension.isMobile) const HSpace(placeholderWidth),
          const Expanded(child: SubscribeButtons()),
          const SizedBox(
            width: placeholderWidth,
            height: 28,
            child: Row(
              children: [
                Spacer(),
                LanguageSelectorOnWelcomePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubscribeButtons extends StatelessWidget {
  const SubscribeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowyText.regular(
              LocaleKeys.youCanAlso.tr(),
              fontSize: FontSizes.s12,
            ),
            FlowyTextButton(
              LocaleKeys.githubStarText.tr(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              fontWeight: FontWeight.w500,
              fontColor: Theme.of(context).colorScheme.primary,
              hoverColor: Colors.transparent,
              fillColor: Colors.transparent,
              onPressed: () =>
                  afLaunchUrlString('https://github.com/AppFlowy-IO/appflowy'),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowyText.regular(LocaleKeys.and.tr(), fontSize: FontSizes.s12),
            FlowyTextButton(
              LocaleKeys.subscribeNewsletterText.tr(),
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              fontWeight: FontWeight.w500,
              fontColor: Theme.of(context).colorScheme.primary,
              hoverColor: Colors.transparent,
              fillColor: Colors.transparent,
              onPressed: () =>
                  afLaunchUrlString('https://www.appflowy.io/blog'),
            ),
          ],
        ),
      ],
    );
  }
}

class LanguageSelectorOnWelcomePage extends StatelessWidget {
  const LanguageSelectorOnWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      offset: const Offset(0, -450),
      direction: PopoverDirection.bottomWithRightAligned,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const FlowySvg(FlowySvgs.ethernet_m, size: Size.square(20)),
            const HSpace(4),
            Builder(
              builder: (context) {
                final currentLocale =
                    context.watch<AppearanceSettingsCubit>().state.locale;
                return FlowyText(languageFromLocale(currentLocale));
              },
            ),
            const FlowySvg(FlowySvgs.drop_menu_hide_m, size: Size.square(20)),
          ],
        ),
      ),
      popupBuilder: (BuildContext context) {
        final easyLocalization = EasyLocalization.of(context);
        if (easyLocalization == null) {
          return const SizedBox.shrink();
        }

        return LanguageItemsListView(
          allLocales: easyLocalization.supportedLocales,
        );
      },
    );
  }
}

class LanguageItemsListView extends StatelessWidget {
  const LanguageItemsListView({super.key, required this.allLocales});

  final List<Locale> allLocales;

  @override
  Widget build(BuildContext context) {
    // get current locale from cubit
    final state = context.watch<AppearanceSettingsCubit>().state;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        itemCount: allLocales.length,
        itemBuilder: (context, index) {
          final locale = allLocales[index];
          return LanguageItem(locale: locale, currentLocale: state.locale);
        },
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

class GoButton extends StatelessWidget {
  const GoButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnonUserBloc()..add(const AnonUserEvent.initial()),
      child: BlocListener<AnonUserBloc, AnonUserState>(
        listener: (context, state) async {
          if (state.openedAnonUser != null) {
            await runAppFlowy();
          }
        },
        child: BlocBuilder<AnonUserBloc, AnonUserState>(
          builder: (context, state) {
            final text = state.anonUsers.isEmpty
                ? LocaleKeys.letsGoButtonText.tr()
                : LocaleKeys.signIn_continueAnonymousUser.tr();

            final textWidget = Row(
              children: [
                Expanded(
                  child: FlowyText.medium(
                    text,
                    textAlign: TextAlign.center,
                    fontSize: 14,
                  ),
                ),
              ],
            );

            return SizedBox(
              width: 340,
              height: 48,
              child: FlowyButton(
                isSelected: true,
                text: textWidget,
                radius: Corners.s6Border,
                onTap: () {
                  if (state.anonUsers.isNotEmpty) {
                    final bloc = context.read<AnonUserBloc>();
                    final historicalUser = state.anonUsers.first;
                    bloc.add(
                      AnonUserEvent.openAnonUser(historicalUser),
                    );
                  } else {
                    onPressed();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SkipLoginMoveWindow extends StatelessWidget
    implements PreferredSizeWidget {
  const _SkipLoginMoveWindow();

  @override
  Widget build(BuildContext context) =>
      const Row(children: [Expanded(child: MoveWindowDetector())]);

  @override
  Size get preferredSize => const Size.fromHeight(55.0);
}
