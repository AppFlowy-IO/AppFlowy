import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class TrashStackContext extends HomeStackContext {
  @override
  String get identifier => "TrashStackContext";

  @override
  List<Object?> get props => ["TrashStackContext"];

  @override
  Widget get titleWidget => const FlowyText.medium('Trash', fontSize: 12);

  @override
  HomeStackType get type => HomeStackType.trash;

  @override
  Widget render() {
    return const TrashStackPage();
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}

class TrashStackPage extends StatefulWidget {
  const TrashStackPage({Key? key}) : super(key: key);

  @override
  State<TrashStackPage> createState() => _TrashStackPageState();
}

class _TrashStackPageState extends State<TrashStackPage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(),
        ),
      ),
    );
  }
}
