import 'package:app_flowy/home/domain/page_context.dart';
import 'package:flutter/material.dart';

abstract class HomeStackPage extends StatefulWidget {
  final PageContext pageContext;
  const HomeStackPage({Key? key, required this.pageContext}) : super(key: key);
}
