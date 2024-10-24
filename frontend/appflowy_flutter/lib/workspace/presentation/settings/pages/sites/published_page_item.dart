import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

final _dateFormat = DateFormat('MMM d, yyyy');
final _publishPageHeaderTitles = [
  // todo: i18n
  'Page',
  'Published by',
  'Published date',
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
          child: _PublishedViewItem(
            publishInfoView: publishInfoView,
          ),
        ),
        // Published Name
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FlowyText(
              publishInfoView.info.publishName,
              fontSize: 14.0,
              overflow: TextOverflow.ellipsis,
            ),
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

class _PublishedViewItem extends StatelessWidget {
  const _PublishedViewItem({
    required this.publishInfoView,
  });

  final PublishInfoViewPB publishInfoView;

  @override
  Widget build(BuildContext context) {
    final icon = publishInfoView.view.icon.value;
    final name = publishInfoView.view.name;
    return Row(
      children: [
        ...icon.isNotEmpty
            ? [
                FlowyText.emoji(
                  icon,
                  fontSize: 16.0,
                  figmaLineHeight: 18.0,
                ),
                const HSpace(2.0),
              ]
            : [
                const HSpace(1.0),
                publishInfoView.view.defaultIcon(),
                const HSpace(5.0),
              ],
        FlowyText.regular(
          name.orDefault(
            LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
          ),
          fontSize: 14.0,
          overflow: TextOverflow.ellipsis,
          figmaLineHeight: 18.0,
        ),
      ],
    );
  }
}
