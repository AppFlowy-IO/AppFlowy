import 'package:app_flowy/home/domain/page_context.dart';
import 'package:app_flowy/home/presentation/widgets/blank_page.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: null,
    );
  }
}

extension PageTypeExtension on PageType {
  HomeStackPage builder(PageContext context) {
    switch (this) {
      case PageType.blank:
        return BlankPage(context: context);
    }
  }
}

List<Widget> buildPagesWidget(PageContext pageContext) {
  return PageType.values.map((pageType) {
    if (pageType == pageContext.pageType) {
      return pageType.builder(pageContext);
    } else {
      return BlankPage(context: BlankPageContext());
    }
  }).toList();
}
