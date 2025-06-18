import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_role_badge.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/profile_card_more_button.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/profile_invite_button.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonProfileCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final mouseRegionPlaceHolder = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: triggerSize.width,
        height: triggerSize.height,
        color: Colors.black.withAlpha(1),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: showAtBottom
          ? [mouseRegionPlaceHolder, buildDecoratedCard(context)]
          : [buildDecoratedCard(context), mouseRegionPlaceHolder],
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
    if (person == null) return const SizedBox.shrink();

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
          child: buildAvatar(context),
        ),
      ],
    );
  }

  Widget buildCover(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    final person = personState.person, url = person?.coverImageUrl ?? '';
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

  Widget buildAvatar(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    final person = personState.person, url = person?.avatarUrl ?? '';
    if (url.isEmpty) return const SizedBox.shrink();
    final hasCover = person?.coverImageUrl?.isNotEmpty ?? false;

    final theme = AppFlowyTheme.of(context);
    final avatar = SizedBox.square(
      dimension: 90,
      child: AFAvatar(
        url: url,
        radius: 41,
        name: person?.name,
        backgroundColor: Colors.transparent,
      ),
    );
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

  Widget buildPersonInfo(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildName(context),
        buildEmail(context),
        buildDescription(context),
        VSpace(theme.spacing.xxl),
        buildActions(context),
      ],
    );
  }

  Widget buildName(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    final theme = AppFlowyTheme.of(context);
    final suffixIcon = context.buildSuffixIcon();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            personState.person?.name ?? '',
            style: theme.textStyle.title
                .prominent(color: theme.textColorScheme.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (suffixIcon != null) suffixIcon,
      ],
    );
  }

  Widget buildEmail(BuildContext context) {
    final person = context.read<PersonBloc>().state.person;
    final theme = AppFlowyTheme.of(context);
    return Text(
      person?.email ?? '',
      style:
          theme.textStyle.body.standard(color: theme.textColorScheme.secondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildDescription(BuildContext context) {
    final person = context.read<PersonBloc>().state.person,
        description = person?.description;
    if (description?.isEmpty ?? true) return const SizedBox.shrink();
    final theme = AppFlowyTheme.of(context);
    return Container(
      margin: EdgeInsets.only(top: theme.spacing.m),
      width: double.infinity,
      child: DecoratedBox(
        decoration: buildDescriptionDecoration(context),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.l),
          child: Text(
            description!,
            style: theme.textStyle.caption
                .standard(color: theme.textColorScheme.primary),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget buildActions(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final person = context.read<PersonBloc>().state.person;
    if (person == null) return const SizedBox.shrink();

    return Row(
      children: [
        PersonRoleBadge(role: person.role),
        Spacer(),
        context.buildNotificationButton(),
        HSpace(theme.spacing.m),
        ProfileCardMoreButton(
          onEnter: onEnter,
          onExit: onExit,
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

  Decoration buildDescriptionDecoration(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BoxDecoration(
      color: theme.fillColorScheme.contentVisible,
      borderRadius: BorderRadius.circular(theme.spacing.m),
    );
  }

  void openEmailApp(Person person) {
    afLaunchUrlString('mailto:${person.email}');
  }
}

extension PersonProfileCardWidgetExtension on BuildContext {
  Widget? buildSuffixIcon() {
    final personState = read<PersonBloc>().state,
        person = personState.person,
        access = personState.access,
        theme = AppFlowyTheme.of(this);
    if (person == null) return null;
    if (!access) {
      return FlowySvg(
        FlowySvgs.no_access_suffix_icon_m,
        color: theme.iconColorScheme.tertiary,
        blendMode: null,
        size: Size.square(20),
      );
    }
    if (person.role == PersonRole.contact) {
      return FlowySvg(
        FlowySvgs.contact_suffix_icon_m,
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
    if (person == null) return const SizedBox.shrink();
    final hasAccess = personState.access,
        isContact = person.role == PersonRole.contact;
    if (isContact) {
      return AFOutlinedButton.normal(
        padding: EdgeInsets.all(theme.spacing.s),
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
    return AFOutlinedButton.normal(
      padding: EdgeInsets.all(theme.spacing.s),
      builder: (context, hovering, disabled) {
        return FlowySvg(
          FlowySvgs.mention_send_notification_m,
          size: Size.square(20),
          color: theme.iconColorScheme.primary,
        );
      },
      onTap: () {},
    );
  }
}
