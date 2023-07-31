import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/personal_folder.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class SidebarFolder extends StatelessWidget {
  const SidebarFolder({
    super.key,
    required this.views,
  });

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // personal
        PersonalFolder(views: views),
      ],
    );
  }
}
