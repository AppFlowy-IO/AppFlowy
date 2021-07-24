import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:flutter/material.dart';

class HomeTopBar extends StatelessWidget {
  final String title;
  const HomeTopBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: HomeInsets.topBarTitlePadding),
      height: HomeSizes.topBarHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HomeTitle(title: title),
        ],
      ),
    );
  }
}

class HomeTitle extends StatelessWidget {
  final String title;
  final _editingController = TextEditingController(
    text: '',
  );

  HomeTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _editingController.text = title;

    return Expanded(
      child: TextField(
        controller: _editingController,
        textAlign: TextAlign.left,
        style: const TextStyle(fontSize: 28.0),
        decoration: const InputDecoration(
          hintText: 'Name the view',
          border: UnderlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
