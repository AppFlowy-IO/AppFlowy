import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_profile_card.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_role_badge.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/profile_card_more_button.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobilePersonProfileCard extends StatelessWidget {
  const MobilePersonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCard(context);
  }

  Widget buildCard(BuildContext context) {
    final theme = AppFlowyTheme.of(context),
        spacing = theme.spacing,
        xl = spacing.xl;

    final personState = context.read<PersonBloc>().state,
        person = personState.person;
    if (person == null) {
      return Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    final hasCover = person.coverImageUrl?.isNotEmpty ?? false;
    final sizeWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            buildCover(context),
            SizedBox(
              width: sizeWidth - xl * 2,
              child: Padding(
                padding: EdgeInsets.only(top: hasCover ? 64 : 0),
                child: buildPersonInfo(context),
              ),
            ),
          ],
        ),
        Positioned(
          left: hasCover ? xl : 0,
          top: hasCover ? 38 : 0,
          child: buildAvatar(context),
        ),
      ],
    );
  }

  Widget buildCover(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    final person = personState.person, url = person?.coverImageUrl ?? '';
    if (url.isEmpty) return VSpace(100);
    final theme = AppFlowyTheme.of(context), xl = theme.spacing.xl;
    final sizeWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: sizeWidth - xl * 2,
      height: 92,
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
        buildNotificationButton(context),
        HSpace(theme.spacing.m),
        ProfileCardMoreButton(),
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
      onTap: () {
        if (isContact) openEmailApp(person);
      },
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
