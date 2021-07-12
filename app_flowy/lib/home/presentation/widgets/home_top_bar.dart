import 'package:app_flowy/home/application/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home_sizes.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: HomeInsets.topBarTitlePadding),
      height: HomeSizes.topBarHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HomeTitle(),
        ],
      ),
    );
  }
}

class HomeTitle extends StatelessWidget {
  final _editingController = TextEditingController(
    text: '',
  );

  HomeTitle({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _editingController.text =
        context.read<HomeBloc>().state.pageContext.pageTitle;

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
