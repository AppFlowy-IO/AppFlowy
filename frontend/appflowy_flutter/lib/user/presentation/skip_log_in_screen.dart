import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/locale_keys.g.dart';
import 'folder/folder_widget.dart';
import 'router.dart';
import 'widgets/background.dart';

class SkipLogInScreen extends StatefulWidget {
  final AuthRouter router;
  final AuthService authService;

  const SkipLogInScreen({
    Key? key,
    required this.router,
    required this.authService,
  }) : super(key: key);

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
    //The width should be fit to the longest language name
    const double languageSelectorWidth = 160;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        FlowyLogoTitle(
          title: LocaleKeys.welcomeText.tr(),
          logoSize: const Size.square(40),
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
          width: size.width * 0.5,
          child: FolderWidget(
            createFolderCallback: () async {
              _didCustomizeFolder = true;
            },
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
//Add the width of the language selector to make SubscribeButtons centered to the screen
                    const SizedBox(
                      width: languageSelectorWidth,
                    ),
                    Column(
                      children: [
                        _buildSubscribeButtons(context),
                        const HSpace(4),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: languageSelectorWidth,
                height: 28,
                child: BlocBuilder<AppearanceSettingsCubit,
                    AppearanceSettingsState>(
                  builder: (context, state) {
                    return const LanguageSelectorOnWelcomePage();
                  },
                ),
              ),
            ],
          ),
        ),
        const VSpace(20),
      ],
    );
  }

  Widget _buildSubscribeButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlowyText.regular(
          LocaleKeys.youCanAlso.tr(),
          fontSize: FontSizes.s12,
        ),
        FlowyTextButton(
          LocaleKeys.githubStarText.tr(),
          fontWeight: FontWeight.w500,
          fontColor: Theme.of(context).colorScheme.primary,
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
          onPressed: () => _launchURL(
            'https://github.com/AppFlowy-IO/appflowy',
          ),
        ),
        FlowyText.regular(
          LocaleKeys.and.tr(),
          fontSize: FontSizes.s12,
        ),
        FlowyTextButton(
          LocaleKeys.subscribeNewsletterText.tr(),
          fontWeight: FontWeight.w500,
          fontColor: Theme.of(context).colorScheme.primary,
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
          onPressed: () => _launchURL('https://www.appflowy.io/blog'),
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

  Future<void> _autoRegister(BuildContext context) async {
    final result = await widget.authService.signUpAsGuest();
    result.fold(
      (error) {
        Log.error(error);
      },
      (user) {
        FolderEventGetCurrentWorkspace().send().then((result) {
          _openCurrentWorkspace(context, user, result);
        });
      },
    );
  }

  Future<void> _relaunchAppAndAutoRegister() async {
    await FlowyRunner.run(
      FlowyApp(),
      config: const LaunchConfiguration(
        autoRegistrationSupported: true,
      ),
    );
  }

  void _openCurrentWorkspace(
    BuildContext context,
    UserProfilePB user,
    dartz.Either<WorkspaceSettingPB, FlowyError> workspacesOrError,
  ) {
    workspacesOrError.fold(
      (workspaceSetting) {
        widget.router
            .pushHomeScreenWithWorkSpace(context, user, workspaceSetting);
      },
      (error) {
        Log.error(error);
      },
    );
  }
}

class LanguageSelectorOnWelcomePage extends StatelessWidget {
  const LanguageSelectorOnWelcomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppearanceSettingsCubit>().state;

    return AppFlowyPopover(
      offset: const Offset(0, -450),
      direction: PopoverDirection.bottomWithRightAligned,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.language_rounded,
            weight: 200,
            grade: 200,
            size: 20,
          ),
          const HSpace(4),
          Text(
            languageFromLocale(state.locale),
          ),
          const HSpace(4),
          const Icon(
            Icons.arrow_drop_up,
            weight: 200,
            grade: 200,
            size: 20,
          ),
        ],
      ),
      popupBuilder: (BuildContext context) {
        final allLocales = EasyLocalization.of(context)!.supportedLocales;

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
    return FlowyTextButton(
      LocaleKeys.letsGoButtonText.tr(),
      constraints: const BoxConstraints(
        maxWidth: 340,
        maxHeight: 48,
      ),
      radius: BorderRadius.circular(12),
      mainAxisAlignment: MainAxisAlignment.center,
      fontSize: FontSizes.s14,
      fontFamily: GoogleFonts.poppins(fontWeight: FontWeight.w500).fontFamily,
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      onPressed: onPressed,
      fillColor: Theme.of(context).colorScheme.primary,
      fontColor: Theme.of(context).colorScheme.onPrimary,
      hoverColor: Theme.of(context).colorScheme.primaryContainer,
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
