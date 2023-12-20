import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/members/members_settings_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsMembersView extends StatelessWidget {
  const SettingsMembersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MembersSettingsBloc>(
      create: (context) =>
          MembersSettingsBloc()..add(const MembersSettingsEvent.started()),
      child: BlocBuilder<MembersSettingsBloc, MembersSettingsState>(
        builder: (context, state) => state.maybeWhen(
          // Initial + Loading in one
          orElse: () => const Center(child: CircularProgressIndicator()),
          failure: () => const _MembersSettingsFailure(),
          data: (data) => MembersSettingsContent(data: data),
        ),
      ),
    );
  }
}

class _MembersSettingsFailure extends StatelessWidget {
  const _MembersSettingsFailure();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FlowyText.semibold(
        LocaleKeys.settings_members_failureText.tr(),
      ),
    );
  }
}

class MembersSettingsContent extends StatelessWidget {
  const MembersSettingsContent({
    super.key,
    required this.data,
  });

  final MembersSettingsData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InviteMembers(),
            const VSpace(16),
            InviteLink(link: data.inviteLink),
            const VSpace(16),
            Divider(color: Theme.of(context).dividerColor),
            const VSpace(16),
            ManageMembers(members: data.members),
          ],
        ),
      ),
    );
  }
}

class InviteMembers extends StatelessWidget {
  InviteMembers({super.key});

  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.bold(
          LocaleKeys.settings_members_inviteMembers.tr(),
          fontSize: 16,
        ),
        const VSpace(8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'email',
                    hintStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13.5,
                      horizontal: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    labelStyle: Theme.of(context).textTheme.bodySmall!,
                  ),
                  onSubmitted: (value) => _invite(context, value),
                ),
              ),
            ),
            const HSpace(10),
            RoundedTextButton(
              title: LocaleKeys.settings_members_sendInviteAction.tr(),
              textColor: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 48,
              width: 112,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _invite(context, _emailController.text),
            ),
          ],
        ),
      ],
    );
  }

  void _invite(BuildContext context, String email) => context
      .read<MembersSettingsBloc>()
      .add(MembersSettingsEvent.invite(email: email));
}

class InviteLink extends StatelessWidget {
  const InviteLink({super.key, required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.medium(
          LocaleKeys.settings_members_inviteLink.tr(),
          fontSize: 16,
        ),
        const VSpace(8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(link),
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async => await getIt<ClipboardService>()
                  .setData(ClipboardServiceData(plainText: link))
                  .then(
                    (_) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: FlowyText(
                          LocaleKeys.settings_members_linkCopiedMessage.tr(),
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: FlowyTooltip(
                  message: LocaleKeys.settings_members_copyLinkTooltip.tr(),
                  child: Container(
                    width: 42,
                    height: 40,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child:
                        const FlowySvg(FlowySvgs.copy_s, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ManageMembers extends StatefulWidget {
  const ManageMembers({
    super.key,
    required this.members,
  });

  final List<MockMember> members;

  @override
  State<ManageMembers> createState() => _ManageMembersState();
}

class _ManageMembersState extends State<ManageMembers> {
  final TextEditingController _searchController = TextEditingController();
  late List<MockMember> _filteredMembers = widget.members;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchValue = _searchController.text.toLowerCase();
    if (searchValue.isEmpty) {
      _filteredMembers = widget.members;
    } else {
      _filteredMembers = widget.members
          .where((m) => m.name.toLowerCase().contains(searchValue))
          .toList();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.bold(LocaleKeys.settings_members_members.tr(), fontSize: 16),
        const VSpace(8),
        // Member Search
        Container(
          height: 36,
          constraints: BoxConstraints.loose(const Size.fromWidth(325)),
          // TODO: Input Validation
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
            decoration: InputDecoration(
              hintText: LocaleKeys.settings_members_searchMembersHint.tr(),
              hintStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              labelStyle: Theme.of(context).textTheme.bodySmall!,
            ),
          ),
        ),
        const VSpace(8),
        // Member List
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: FlowyText.bold(
                      LocaleKeys.settings_members_user.tr(),
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: FlowyText.bold(
                      LocaleKeys.settings_members_role.tr(),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(8),
                1: FlexColumnWidth(7),
                2: FixedColumnWidth(32),
                3: FixedColumnWidth(32),
              },
              children: _filteredMembers
                  .map(
                    (m) => TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16) +
                              const EdgeInsets.symmetric(vertical: 8),
                          child: FlowyText(m.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16) +
                              const EdgeInsets.symmetric(vertical: 8),
                          child: FlowyText(m.role),
                        ),
                        AppFlowyPopover(
                          constraints: BoxConstraints.loose(
                            const Size(212, 221),
                          ),
                          direction: PopoverDirection.leftWithCenterAligned,
                          popupBuilder: (_) => const Placeholder(),
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: FlowySvg(
                                FlowySvgs.arrow_down_s,
                                size: Size.square(16),
                              ),
                            ),
                          ),
                        ),
                        AppFlowyPopover(
                          constraints: BoxConstraints.loose(
                            const Size(212, 221),
                          ),
                          direction: PopoverDirection.leftWithCenterAligned,
                          popupBuilder: (_) => const _ActionsMenu(),
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: FlowySvg(
                                FlowySvgs.three_dots_vertical_s,
                                size: Size.square(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyButton(
          text: FlowyText(LocaleKeys.settings_members_actions_remove.tr()),
          leftIcon: const FlowySvg(FlowySvgs.close_s),
          leftIconSize: const Size.square(20),
          // TODO: Remove member
          onTap: () {},
        ),
      ],
    );
  }
}

// TODO: Remove
class MockMember extends Equatable {
  const MockMember({required this.name, required this.role});

  final String name;
  final String role;

  @override
  List<Object?> get props => [name, role];
}

const mockedMembers = [
  MockMember(name: "John Smith", role: "Owner"),
  MockMember(name: "Carrey Fisher", role: "Teamspace Owner"),
  MockMember(name: "Mr. Crabs", role: "Member"),
  MockMember(name: "Bruce Willis", role: "Guest"),
  MockMember(name: "Gary Oldman", role: "Guest"),
  MockMember(name: "Milla Jovovich", role: "Guest"),
];
