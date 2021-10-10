import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuTopBar extends StatelessWidget {
  const MenuTopBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return SizedBox(
          height: 48,
          child: Row(
            children: [
              svgWithSize("flowy_logo_with_text", const Size(92, 17)),
              const Spacer(),
              IconButton(
                iconSize: 16,
                icon: svg("home/hide_menu"),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.zero,
                onPressed: () => context.read<MenuBloc>().add(const MenuEvent.collapse()),
              ),
            ],
          ),
        );
      },
    );
  }
}
