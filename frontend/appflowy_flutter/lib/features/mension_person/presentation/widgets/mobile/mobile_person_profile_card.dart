import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_profile_card.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_role_badge.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/profile_card_more_button.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobilePersonProfileCard extends StatefulWidget {
  const MobilePersonProfileCard({super.key});

  @override
  State<MobilePersonProfileCard> createState() =>
      _MobilePersonProfileCardState();
}

class _MobilePersonProfileCardState extends State<MobilePersonProfileCard> {
  final popoverController = PopoverController();

  @override
  void dispose() {
    hidePopover();
    super.dispose();
  }

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
    if (person.isEmpty) {
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
          child: context.buildAvatar(),
        ),
      ],
    );
  }

  Widget buildCover(BuildContext context) {
    final personState = context.read<PersonBloc>().state;
    final person = personState.person, url = person.coverImageUrl ?? '';
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
    final state = context.read<PersonBloc>().state;
    if (state.person.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        PersonRoleBadge(
          person: state.person,
          access: state.access,
        ),
        Spacer(),
        context.buildNotificationButton(),
        HSpace(theme.spacing.m),
        ProfileCardMoreButton(popoverController: popoverController),
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
