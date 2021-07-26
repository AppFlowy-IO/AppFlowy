import 'package:app_flowy/workspace/presentation/widgets/menu/menu_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class UserProfile extends MenuItem {
  const UserProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 30,
        height: 30,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const Image(image: AssetImage('assets/images/avatar.jpg')),
        ),
      ),
      const HSpace(6),
      const Text("nathan", style: TextStyle(fontSize: 18)),
    ]);
  }

  @override
  MenuItemType get type => MenuItemType.userProfile;
}
