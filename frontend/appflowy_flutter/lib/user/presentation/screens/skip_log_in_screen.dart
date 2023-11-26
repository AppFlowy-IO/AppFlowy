import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/historical_user_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/widgets/widgets.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class SkipLogInScreen extends StatefulWidget {
  static const routeName = '/SkipLogInScreen';

  const SkipLogInScreen({
    super.key,
  });

  @override
  State<SkipLogInScreen> createState() => _SkipLogInScreenState();
}

class _SkipLogInScreenState extends State<SkipLogInScreen> {
  var _didCustomizeFolder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _SkipLoginMoveWindow(),
      body: Center(
        child: _renderBody(context),
      ),
    );
  }

  Widget _renderBody(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
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
        const VSpace(32),
        SizedBox(
          width: size.width * 0.7,
          child: FolderWidget(
            createFolderCallback: () async {
              _didCustomizeFolder = true;
            },
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
      (error) {
        Log.error(error);
      },
      (user) {
        getIt<AuthRouter>().goHomeScreen(context, user);
      },
    );
  }

  Future<void> _relaunchAppAndAutoRegister() async {
    await FlowyRunner.run(
      FlowyApp(),
      integrationMode(),
      config: const LaunchConfiguration(
        autoRegistrationSupported: true,
      ),
    );
  }
}

class SkipLoginPageFooter extends StatelessWidget {
  const SkipLoginPageFooter({
    super.key,
  });

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
  const SubscribeButtons({
    super.key,
  });

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
              onPressed: () => _launchURL(
                'https://github.com/AppFlowy-IO/appflowy',
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowyText.regular(
              LocaleKeys.and.tr(),
              fontSize: FontSizes.s12,
            ),
            FlowyTextButton(
              LocaleKeys.subscribeNewsletterText.tr(),
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              fontWeight: FontWeight.w500,
              fontColor: Theme.of(context).colorScheme.primary,
              hoverColor: Colors.transparent,
              fillColor: Colors.transparent,
              onPressed: () => _launchURL('https://www.appflowy.io/blog'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class LanguageSelectorOnWelcomePage extends StatelessWidget {
  const LanguageSelectorOnWelcomePage({
    super.key,
  });

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
            const FlowySvg(
              FlowySvgs.ethernet_m,
              size: Size.square(20),
            ),
            const HSpace(4),
            Builder(
              builder: (context) {
                final currentLocale =
                    context.watch<AppearanceSettingsCubit>().state.locale;
                return FlowyText(
                  languageFromLocale(currentLocale),
                );
              },
            ),
            const FlowySvg(
              FlowySvgs.drop_menu_hide_m,
              size: Size.square(20),
            ),
          ],
        ),
      ),
      popupBuilder: (BuildContext context) {
        final easyLocalization = EasyLocalization.of(context);
        if (easyLocalization == null) {
          return const SizedBox.shrink();
        }
        final allLocales = easyLocalization.supportedLocales;
        return LanguageItemsListView(
          allLocales: allLocales,
        );
      },
    );
  }
}

class GoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoricalUserBloc()
        ..add(
          const HistoricalUserEvent.initial(),
        ),
      child: BlocListener<HistoricalUserBloc, HistoricalUserState>(
        listenWhen: (previous, current) =>
            previous.openedHistoricalUser != current.openedHistoricalUser,
        listener: (context, state) async {
          await runAppFlowy();
        },
        child: BlocBuilder<HistoricalUserBloc, HistoricalUserState>(
          builder: (context, state) {
            final text = state.historicalUsers.isEmpty
                ? LocaleKeys.letsGoButtonText.tr()
                : LocaleKeys.signIn_continueAnonymousUser.tr();

            final textWidget = FlowyText.medium(
              text,
              textAlign: TextAlign.center,
              fontSize: 14,
            );

            return SizedBox(
              width: 340,
              height: 48,
              child: FlowyButton(
                isSelected: true,
                text: textWidget,
                radius: Corners.s6Border,
                onTap: () {
                  if (state.historicalUsers.isNotEmpty) {
                    final bloc = context.read<HistoricalUserBloc>();
                    final historicalUser = state.historicalUsers.first;
                    bloc.add(
                      HistoricalUserEvent.openHistoricalUser(historicalUser),
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
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: MoveWindowDetector(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(55.0);
}
