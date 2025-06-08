import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_role_badge.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonCardProfile extends StatelessWidget {
  const PersonCardProfile({
    super.key,
    required this.triggerSize,
  });

  final Size triggerSize;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCard(context),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: triggerSize.width,
            height: triggerSize.height,
            color: Colors.black.withAlpha(1),
          ),
        ),
      ],
    );
  }

  Widget buildCard(BuildContext context) {
    final theme = AppFlowyTheme.of(context), xxl = theme.spacing.xxl;
    final personState = context.read<PersonBloc>().state,
        person = personState.person;
    if (person == null) return const SizedBox.shrink();

    final hasCover = person.coverImageUrl?.isNotEmpty ?? false;

    return DecoratedBox(
      decoration: buildCardDecoration(context),
      child: Stack(
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
      ),
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
    return Text(
      personState.person?.name ?? '',
      style:
          theme.textStyle.title.prominent(color: theme.textColorScheme.primary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
        buildNotificationButton(context),
        HSpace(theme.spacing.m),
        buildMoreButton(context),
      ],
    );
  }

  Widget buildNotificationButton(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final person = context.read<PersonBloc>().state.person;
    if (person == null) return const SizedBox.shrink();
    final isContact = person.role == PersonRole.contact;
    return AFOutlinedButton.normal(
      padding: EdgeInsets.all(theme.spacing.s),
      builder: (context, hovering, disabled) {
        return FlowySvg(
          isContact
              ? FlowySvgs.mention_send_email_m
              : FlowySvgs.mention_send_notification_m,
          size: Size.square(20),
          color: theme.iconColorScheme.primary,
        );
      },
      onTap: () {},
    );
  }

  Widget buildMoreButton(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final person = context.read<PersonBloc>().state.person;
    if (person == null) return const SizedBox.shrink();
    return AFOutlinedButton.normal(
      padding: EdgeInsets.all(theme.spacing.s),
      builder: (context, hovering, disabled) {
        return FlowySvg(
          FlowySvgs.mention_more_results_m,
          size: Size.square(20),
          color: theme.iconColorScheme.primary,
        );
      },
      onTap: () {},
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
}
