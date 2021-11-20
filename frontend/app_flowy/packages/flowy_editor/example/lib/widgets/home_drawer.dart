import 'package:flutter/material.dart';

class HomeDrawer extends StatelessWidget {
  final Widget drawer;
  final Widget body;

  const HomeDrawer({
    Key key,
    this.drawer,
    this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final appBar = AppBar(
          title: Text('Flowy Editor Example'),
        );
        if (constraints.maxWidth < 800) {
          return Scaffold(
            appBar: appBar,
            drawer: drawer,
            body: body,
          );
        }
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                constraints: BoxConstraints(minWidth: 250, maxWidth: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    appBar,
                    Expanded(child: drawer),
                  ],
                ),
              ),
              VerticalDivider(width: 1.0),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
