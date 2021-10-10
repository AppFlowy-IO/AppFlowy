import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class DefaultHomeStackContext extends HomeStackContext {
  @override
  String get identifier => "1";

  @override
  List<Object?> get props => ["1"];

  @override
  String get title => "Blank page";

  @override
  ViewType get type => ViewType.Blank;

  @override
  Widget render() {
    return const AnnouncementStackPage();
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}

class AnnouncementStackPage extends StatefulWidget {
  const AnnouncementStackPage({Key? key}) : super(key: key);

  @override
  State<AnnouncementStackPage> createState() => _AnnouncementPage();
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
