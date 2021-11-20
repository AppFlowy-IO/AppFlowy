import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuTopBar extends StatelessWidget {
  const MenuTopBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return SizedBox(
          height: HomeSizes.topBarHeight,
          child: Row(
            children: [
              svgWithSize("flowy_logo_with_text", const Size(92, 17)),
              const Spacer(),
              FlowyIconButton(
                width: 28,
                onPressed: () => context.read<MenuBloc>().add(const MenuEvent.collapse()),
                iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                icon: svg("home/hide_menu"),
              )
            ],
          ),
        );
      },
    );
  }
}
