import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flutter/material.dart';

abstract class HomeStackPage extends StatefulWidget {
  final HomeStackView pageContext;
  const HomeStackPage({Key? key, required this.pageContext}) : super(key: key);
}
