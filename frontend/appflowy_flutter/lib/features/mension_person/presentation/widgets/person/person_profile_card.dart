import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_role_badge.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/profile_card_more_button.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/profile_invite_button.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

class PersonProfileCard extends StatefulWidget {
  const PersonProfileCard({
    super.key,
    required this.triggerSize,
    required this.showAtBottom,
    this.onEnter,
    this.onExit,
  });

  final Size triggerSize;
  final bool showAtBottom;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;

  @override
  State<PersonProfileCard> createState() => _PersonProfileCardState();
}

class _PersonProfileCardState extends State<PersonProfileCard> {
  final popoverController = PopoverController();

  @override
  void dispose() {
    hidePopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mouseRegionPlaceHolder = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: widget.triggerSize.width,
        height: widget.triggerSize.height,
        color: Colors.black.withAlpha(1),
      ),
    );
    return GestureDetector(
      onTap: hidePopover,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: widget.showAtBottom
            ? [mouseRegionPlaceHolder, buildDecoratedCard(context)]
            : [buildDecoratedCard(context), mouseRegionPlaceHolder],
      ),
    );
  }

  Widget buildDecoratedCard(BuildContext context) => DecoratedBox(
        decoration: buildCardDecoration(context),
        child: buildCard(context),
      );

  Widget buildCard(BuildContext context) {
    final theme = AppFlowyTheme.of(context), xxl = theme.spacing.xxl;
    final personState = context.read<PersonBloc>().state,
        person = personState.person;
    if (person.isEmpty) return const SizedBox.shrink();

    final hasCover = person.coverImageUrl?.isNotEmpty ?? false;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            buildCover(context),
            SizedBox(
              width: 280,
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(xxl, hasCover ? 60 : xxl, xxl, xxl),
                child: buildPersonInfo(context),
              ),
            ),
          ],
        ),
        Positioned(
          left: xxl,
          top: hasCover ? 38 : xxl,
          child: context.buildAvatar(),
        ),
      ],
    );
  }

  Widget buildCover(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    final person = personState.person, url = person.coverImageUrl ?? '';
    if (url.isEmpty) return VSpace(100);
    final theme = AppFlowyTheme.of(context), spaceM = theme.spacing.m;
    return Container(
      width: 280,
      height: 88,
      padding: EdgeInsets.fromLTRB(spaceM, spaceM, spaceM, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.spacing.m),
        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
      ),
    );
  }

  Widget buildPersonInfo(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        context.buildPersonName(),
        context.buildPersonEmail(),
        context.buildPersonDescription(),
        VSpace(theme.spacing.xxl),
        buildActions(context),
      ],
    );
  }

  Widget buildEmail(BuildContext context) {
    final person = context.read<PersonBloc>().state.person;
    final theme = AppFlowyTheme.of(context);
    return Text(
      person.email,
      style:
          theme.textStyle.body.standard(color: theme.textColorScheme.secondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildActions(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final state = context.read<PersonBloc>().state,
        access = state.access,
        person = state.person;
    if (person.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        PersonRoleBadge(person: person, access: access),
        Spacer(),
        context.buildNotificationButton(),
        HSpace(theme.spacing.m),
        ProfileCardMoreButton(
          onEnter: widget.onEnter,
          onExit: widget.onExit,
          popoverController: popoverController,
        ),
      ],
    );
  }

  Decoration buildCardDecoration(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BoxDecoration(
      color: theme.surfaceColorScheme.layer01,
      borderRadius: BorderRadius.circular(theme.spacing.l),
      boxShadow: theme.shadow.small,
    );
  }

  void openEmailApp(Person person) {
    afLaunchUrlString('mailto:${person.email}');
  }

  void hidePopover() {
    popoverController.close();
  }
}

extension PersonProfileCardWidgetExtension on BuildContext {
  Widget buildPersonName() {
    final person = read<PersonBloc>().state.person;
    final theme = AppFlowyTheme.of(this);
    final suffixIcon = buildSuffixIcon();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            person.name,
            style: theme.textStyle.title.prominent(
              color: person.deleted
                  ? theme.textColorScheme.tertiary
                  : theme.textColorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (suffixIcon != null) suffixIcon,
      ],
    );
  }

  Widget buildPersonEmail() {
    final person = read<PersonBloc>().state.person,
        theme = AppFlowyTheme.of(this);
    return Text(
      person.email,
      style: theme.textStyle.body.standard(
        color: person.deleted
            ? theme.textColorScheme.tertiary
            : theme.textColorScheme.secondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildPersonDescription() {
    final person = read<PersonBloc>().state.person,
        description = person.description;
    if (description?.isEmpty ?? true) return const SizedBox.shrink();
    final theme = AppFlowyTheme.of(this);
    return Container(
      margin: EdgeInsets.only(top: theme.spacing.m),
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.fillColorScheme.contentVisible,
          borderRadius: BorderRadius.circular(theme.spacing.m),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.l),
          child: Text(
            description!,
            style: theme.textStyle.caption.standard(
              color: person.deleted
                  ? theme.textColorScheme.tertiary
                  : theme.textColorScheme.primary,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget? buildSuffixIcon() {
    final personState = read<PersonBloc>().state,
        person = personState.person,
        access = personState.access,
        theme = AppFlowyTheme.of(this);
    if (person.isEmpty) return null;
    if (person.role == PersonRole.contact) {
      return FlowySvg(
        FlowySvgs.contact_suffix_icon_m,
        color: theme.iconColorScheme.tertiary,
        blendMode: null,
        size: Size.square(20),
      );
    }
    if (!access && !person.deleted) {
      return FlowySvg(
        FlowySvgs.no_access_suffix_icon_m,
        color: theme.iconColorScheme.tertiary,
        blendMode: null,
        size: Size.square(20),
      );
    }
    return null;
  }

  Widget buildNotificationButton() {
    final theme = AppFlowyTheme.of(this);
    final personBloc = read<PersonBloc>(),
        personState = personBloc.state,
        person = personState.person;
    if (person.isEmpty || person.deleted) return const SizedBox.shrink();
    final hasAccess = personState.access,
        isContact = person.role == PersonRole.contact;
    if (isContact) {
      return AFOutlinedButton.normal(
        padding:
            EdgeInsets.all(UniversalPlatform.isMobile ? 10 : theme.spacing.s),
        builder: (context, hovering, disabled) {
          return FlowySvg(
            FlowySvgs.mention_send_email_m,
            size: Size.square(20),
            color: theme.iconColorScheme.primary,
          );
        },
        onTap: () => afLaunchUrlString('mailto:${person.email}'),
      );
    }
    if (!hasAccess) {
      return ProfileInviteButton(
        onTap: () {},
      );
    }
    return FlowyTooltip(
      message: LocaleKeys.document_mentionMenu_notificationButtonTooltip.tr(),
      preferBelow: false,
      child: AFOutlinedButton.normal(
        padding:
            EdgeInsets.all(UniversalPlatform.isMobile ? 10 : theme.spacing.s),
        builder: (context, hovering, disabled) {
          return FlowySvg(
            FlowySvgs.mention_send_notification_m,
            size: Size.square(20),
            color: theme.iconColorScheme.primary,
          );
        },
        onTap: () {},
      ),
    );
  }

  Widget buildAvatar() {
    final personState = read<PersonBloc>().state;
    final person = personState.person,
        url = person.avatarUrl ?? '',
        noAccess = !person.deleted &&
            !personState.access &&
            person.role != PersonRole.contact;
    if (url.isEmpty) return const SizedBox.shrink();
    final hasCover = person.coverImageUrl?.isNotEmpty ?? false;

    final theme = AppFlowyTheme.of(this);
    const size = 90.0, radius = 41.0;
    Widget avatar = SizedBox.square(
      dimension: size,
      child: AFAvatar(
        url: url,
        radius: radius,
        name: person.name,
        backgroundColor: Colors.transparent,
      ),
    );
    if (noAccess) {
      avatar = FlowyTooltip(
        message: LocaleKeys.document_mentionMenu_noAccessTooltip.tr(),
        preferBelow: false,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              avatar,
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  color: theme.surfaceColorScheme.overlay,
                ),
                child: Center(
                  child: FlowySvg(
                    FlowySvgs.profile_card_avatar_no_access_m,
                    size: Size.square(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceColorScheme.layer01,
        shape: BoxShape.circle,
      ),
      child: hasCover
          ? SizedBox.square(
              dimension: 100,
              child: Center(child: avatar),
            )
          : avatar,
    );
  }
}
