import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_platform/universal_platform.dart';

/// Opens a message in the right hand sidebar on desktop, and push the page
/// on mobile
void openPageFromMessage(BuildContext context, ViewPB? view) {
  if (view == null) {
    return;
  }
  if (UniversalPlatform.isDesktop) {
    getIt<TabsBloc>().add(
      TabsEvent.openSecondaryPlugin(
        plugin: view.plugin(),
      ),
    );
  } else {
    context.pushView(view);
  }
}
