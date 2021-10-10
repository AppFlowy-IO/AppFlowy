import 'package:flutter/material.dart';
import '../../menu_list.dart';

class FavoriteHeader extends MenuItem {
  const FavoriteHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  MenuItemType get type => MenuItemType.favorites;
}
