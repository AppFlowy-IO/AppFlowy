import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

class SettingsPageSitesConstants {
  static const threeDotsButtonWidth = 26.0;

  static final dateFormat = DateFormat('MMM d, yyyy');

  static final publishedViewHeaderTitles = [
    // todo: i18n
    'Page',
    'Published name',
    'Published date',
  ];

  static final namespaceHeaderTitles = [
    'Namespace',
    'Homepage',
  ];

  // the published view name is longer than the other two, so we give it more flex
  static final publishedViewItemFlexes = [1, 1, 1];

  static final fakeData = [
    PublishInfoViewPB(
      info: PublishInfoResponsePB(
        viewId: '1',
        publishTimestampSec: Int64(1724409600),
        publishName: 'Published 1',
        namespace: 'https://published1.com',
        publisherEmail: 'user1@example.com',
      ),
      view: FolderViewMinimalPB(
        viewId: '1',
        name: 'Page 1',
        layout: ViewLayoutPB.Document,
      ),
    ),
    PublishInfoViewPB(
      info: PublishInfoResponsePB(
        viewId: '2',
        publishTimestampSec: Int64(1724409600),
        publishName: 'Published 2',
        namespace: 'https://published2.com',
        publisherEmail: 'user2@example.com',
      ),
      view: FolderViewMinimalPB(
        viewId: '2',
        name: 'Page 2',
        layout: ViewLayoutPB.Document,
      ),
    ),
    PublishInfoViewPB(
      info: PublishInfoResponsePB(
        viewId: '3',
        publishTimestampSec: Int64(1724409600),
        publishName: 'Published 3',
        namespace: 'https://published3.com',
        publisherEmail: 'user3@example.com',
      ),
      view: FolderViewMinimalPB(
        viewId: '3',
        name: 'Page 3',
        layout: ViewLayoutPB.Document,
      ),
    ),
  ];
}

class SettingsPageSitesEvent {
  static void visitSite(PublishInfoViewPB publishInfoView) {
    // visit the site
    final url = ShareConstants.buildPublishUrl(
      nameSpace: publishInfoView.info.namespace,
      publishName: publishInfoView.info.publishName,
    );
    afLaunchUrlString(url);
  }

  static void copySiteLink(
    BuildContext context,
    PublishInfoViewPB publishInfoView,
  ) {
    final url = ShareConstants.buildPublishUrl(
      nameSpace: publishInfoView.info.namespace,
      publishName: publishInfoView.info.publishName,
    );
    getIt<ClipboardService>().setData(ClipboardServiceData(plainText: url));
    showToastNotification(
      context,
      message: LocaleKeys.grid_url_copy.tr(),
    );
  }
}
