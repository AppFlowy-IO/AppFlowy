import 'package:app_flowy/workspace/presentation/widgets/menu/menu_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flutter/material.dart';

class MenuUser extends MenuItem {
  final UserDetail user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 30,
        height: 30,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: const Image(image: AssetImage('assets/images/avatar.jpg')),
        ),
      ),
      const HSpace(10),
      const Text("nathan", style: TextStyle(fontSize: 18)),
    ]);
  }

  @override
  MenuItemType get type => MenuItemType.userProfile;
}
