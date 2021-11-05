import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      width: 30,
      height: 30,
      child: FlowyTextButton(
        '?',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fillColor: theme.selector,
        mainAxisAlignment: MainAxisAlignment.center,
        radius: BorderRadius.circular(10),
        onPressed: () {},
      ),
    );
  }
}
