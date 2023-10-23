import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileHomePageHeader extends StatelessWidget {
  const MobileHomePageHeader({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    // TODO: implement the details later.
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          const FlowyText(
            '🐻',
            fontSize: 26,
          ),
          const HSpace(14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlowyText.medium(
                'AppFlowy',
                fontSize: 18,
              ),
              const VSpace(4.0),
              FlowyText.regular(
                userProfile.email,
                fontSize: 12,
                color: Colors.grey,
              )
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_horiz_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
