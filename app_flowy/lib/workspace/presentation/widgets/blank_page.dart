import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class AnnouncementStackView extends HomeStackView {
  const AnnouncementStackView()
      : super(type: ViewType.Blank, title: 'Blank', identifier: "Announcement");

  @override
  List<Object> get props => [];
}

class AnnouncementStackPage extends HomeStackWidget {
  const AnnouncementStackPage(
      {Key? key, required AnnouncementStackView stackView})
      : super(key: key, stackView: stackView);

  @override
  State<StatefulWidget> createState() => _AnnouncementPage();
}

class _AnnouncementPage extends State<AnnouncementStackPage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(),
        ),
      ),
    );
  }
}
