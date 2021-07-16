import 'package:example/home/demo_item.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static List<ListItem> items = [
    SectionHeaderItem('Widget Demos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demos'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is SectionHeaderItem) {
            return Container(
              constraints: const BoxConstraints(maxHeight: 48.0),
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: ListTile(
                title: Text(item.title),
              ),
            );
          } else if (item is DemoItem) {
            return ListTile(
              title: Text(item.buildTitle()),
              onTap: item.handleTap,
            );
          }
          return const ListTile(
            title: Text('Unknow.'),
          );
        },
      ),
    );
  }
}
