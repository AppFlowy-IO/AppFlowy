import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class BlankStackContext extends HomeStackContext {
  @override
  String get identifier => "1";

  @override
  List<Object?> get props => ["1"];

  @override
  Widget get titleWidget => const FlowyText.medium('Blank page', fontSize: 12);

  @override
  HomeStackType get type => HomeStackType.blank;

  @override
  Widget render() {
    return const BlankStackPage();
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}

class BlankStackPage extends StatefulWidget {
  const BlankStackPage({Key? key}) : super(key: key);

  @override
  State<BlankStackPage> createState() => _BlankStackPageState();
}

class _BlankStackPageState extends State<BlankStackPage> {
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
