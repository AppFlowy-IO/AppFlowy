import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class HomeStackPage extends StatefulWidget {
  final PageContext pageContext;
  const HomeStackPage({Key? key, required this.pageContext}) : super(key: key);
}

enum PageType {
  blank,
}

List<PageType> pages = PageType.values.toList();

abstract class PageContext extends Equatable {
  final PageType pageType;
  final String pageTitle;
  const PageContext(this.pageType, {required this.pageTitle});
}
