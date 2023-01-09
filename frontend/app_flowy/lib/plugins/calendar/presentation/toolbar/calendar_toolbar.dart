import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';

class CalendarToolbar extends StatelessWidget {
  const CalendarToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          FlowyTextButton(
            "Settings",
            fillColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          ),
        ],
      ),
    );
  }
}
