import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class BlankStackContext extends HomeStackContext {
  final ValueNotifier<bool> _isUpdated = ValueNotifier<bool>(false);

  @override
  String get identifier => "1";

  @override
  Widget get leftBarItem => const FlowyText.medium('Blank page', fontSize: 12);

  @override
  Widget? get rightBarItem => null;

  @override
  HomeStackType get type => HomeStackType.blank;

  @override
  Widget buildWidget() {
    return const BlankStackPage();
  }

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  ValueNotifier<bool> get isUpdated => _isUpdated;

  @override
  void dispose() {}
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
