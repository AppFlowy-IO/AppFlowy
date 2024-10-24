import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';

class SettingsPageSitesConstants {
  static const threeDotsButtonWidth = 26.0;

  static final dateFormat = DateFormat('MMM d, yyyy');

  static final publishedViewHeaderTitles = [
    // todo: i18n
    'Page',
    'Published name',
    'Published date',
  ];

  // the published view name is longer than the other two, so we give it more flex
  static final publishedViewItemFlexes = [1, 1, 1];

  static final fakeData = [
    PublishInfoViewPB(
      info: PublishInfoResponsePB(
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
