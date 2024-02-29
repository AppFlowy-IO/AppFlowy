import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsMemberPage extends StatelessWidget {
  const SettingsMemberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          FlowyText('Members Settings'),
          _InviteMember(),
        ],
      ),
    );
  }
}

class _InviteMember extends StatelessWidget {
  const _InviteMember({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText('Invite member'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: FlowyTextField(),
            ),
            HSpace(4.0),
            FlowyButton(
              useIntrinsicWidth: true,
              text: FlowyText('send invite'),
            ),
          ],
        ),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowyText('Copy invite link'),
        ),
        Divider(),
        _MemberList(),
      ],
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList();

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separatorBuilder: () => const Divider(),
      children: const [
        _MemberItem(),
        _MemberItem(),
        _MemberItem(),
        _MemberItem(),
      ],
    );
  }
}

class _MemberItem extends StatelessWidget {
  const _MemberItem({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: FlowyText('User')),
        Expanded(child: FlowyText('Role')),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(FlowySvgs.delete_s),
        ),
      ],
    );
  }
}
