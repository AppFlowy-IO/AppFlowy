import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class PublishedPageItem extends StatelessWidget {
  const PublishedPageItem({
    super.key,
    required this.publishInfoView,
  });

  final PublishInfoViewPB publishInfoView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlowyText.medium(
          publishInfoView.view.name,
          fontSize: 14.0,
        ),
        // Domain
        FlowyText.medium(
          publishInfoView.info.namespace,
          fontSize: 14.0,
        ),
        // Published by
        FlowyText.medium(
          publishInfoView.info.publisherEmail,
          fontSize: 14.0,
        ),
        // Published at
        FlowyText.medium(
          publishInfoView.info.publishTimestampSec.toString(),
          fontSize: 14.0,
        ),
      ],
    );
  }
}
