import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuTopBar extends StatelessWidget {
  const MenuTopBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return Row(
          children: [
            const Image(
                fit: BoxFit.cover,
                width: 25,
                height: 25,
                image: AssetImage('assets/images/app_flowy_logo.jpg')),
            const HSpace(8),
            const Text(
              'AppFlowy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.arrow_left),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.zero,
              onPressed: () =>
                  context.read<MenuBloc>().add(const MenuEvent.collapse()),
            ),
          ],
        );
      },
    );
  }
}
