import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _dateFormat = DateFormat('MMM d, yyyy');
final _publishPageHeaderTitles = [
  'Page',
  'Published by',
  'Published at',
];

class PublishPageHeader extends StatelessWidget {
  const PublishPageHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _publishPageHeaderTitles
          .map(
            (title) => Expanded(
              child: FlowyText.medium(
                title,
                fontSize: 14.0,
                textAlign: TextAlign.left,
              ),
            ),
          )
          .toList(),
    );
  }
}

class PublishedPageItem extends StatelessWidget {
  const PublishedPageItem({
    super.key,
    required this.publishInfoView,
  });

  final PublishInfoViewPB publishInfoView;

  @override
  Widget build(BuildContext context) {
    final formattedDate = _dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(
        publishInfoView.info.publishTimestampSec.toInt() * 1000,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Published page name
        Expanded(
          child: FlowyText(
            publishInfoView.view.name,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Published by
        Expanded(
          child: FlowyText(
            publishInfoView.info.publisherEmail,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Published at
        Expanded(
          child: FlowyText(
            formattedDate,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
