import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsManageDataView extends StatelessWidget {
  const SettingsManageDataView({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      children: [
        SettingsHeader(
          title: LocaleKeys.settings_manageData_title.tr(),
          description: LocaleKeys.settings_manageData_description.tr(),
        ),
      ],
    );
  }
}
