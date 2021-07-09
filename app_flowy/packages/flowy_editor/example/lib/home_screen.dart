import 'widgets/home_drawer.dart';
import 'widgets/editor_scaffold.dart';
import 'package:flutter/material.dart';

final flowyDocs = [
  'plain_text_document.fdoc',
  'block_document.fdoc',
  'long_document.fdoc',
];

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filename;
  Widget _editor;

  @override
  void initState() {
    filename = flowyDocs[1];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HomeDrawer(
      drawer: Container(
        constraints: BoxConstraints(minWidth: 250, maxWidth: 250),
        color: Colors.white,
        child: ListView.separated(
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _selectDoc(index),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    flowyDocs[index],
                    style: TextStyle(fontSize: 16.0, color: Colors.black54),
                  ),
                ),
              ),
            );
          },
          itemCount: flowyDocs.length,
          separatorBuilder: (context, index) => Divider(),
        ),
      ),
      body: _editor ?? _homepageEditor(),
    );
  }

  Widget _homepageEditor() {
    return EditorScaffold(filename: filename);
  }

  void _selectDoc(int index) {
    final filename = flowyDocs[index];
    setState(() {
      _editor = null;
      this.filename = filename;
    });
  }
}
