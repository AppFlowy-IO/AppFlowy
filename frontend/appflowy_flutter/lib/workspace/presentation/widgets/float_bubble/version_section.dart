import 'package:appflowy/env/env.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';

class FlowyVersionSection extends CustomActionCell {
  @override
  Widget buildWithContext(
    BuildContext context,
    PopoverController controller,
    PopoverMutex? mutex,
  ) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return FlowyText(
              "Error: ${snapshot.error}",
              color: Theme.of(context).disabledColor,
            );
          }

          final PackageInfo packageInfo = snapshot.data;
          final String appName = packageInfo.appName;
          final String version = packageInfo.version;

          return SizedBox(
            height: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                  thickness: 1.0,
                ),
                const VSpace(6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () {
                    if (Env.internalBuild != '1' && !kDebugMode) {
                      return;
                    }
                    enableDocumentInternalLog = !enableDocumentInternalLog;
                    showToastNotification(
                      context,
                      message: enableDocumentInternalLog
                          ? 'Enabled Internal Log'
                          : 'Disabled Internal Log',
                    );
                  },
                  child: FlowyText(
                    '$appName $version',
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ).padding(
                    horizontal: ActionListSizes.itemHPadding,
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox(height: 30);
        }
      },
    );
  }
}
