import 'package:app_flowy/home/application/menu/menu_bloc.dart';
import 'package:app_flowy/home/domain/page_context.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home_sizes.dart';
import 'package:styled_widget/styled_widget.dart';

class HomeMenu extends StatelessWidget {
  final Function(Option<PageContext>) pageContextChanged;
  final Function(bool) isCollapseChanged;

  const HomeMenu(
      {Key? key,
      required this.pageContextChanged,
      required this.isCollapseChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider<MenuBloc>(create: (context) => getIt<MenuBloc>()),
        ],
        child: MultiBlocListener(
          listeners: bind(),
          child: Container(
            color: Theme.of(context).colorScheme.primaryVariant,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Insets.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const MenuTopBar(),
                  Container(),
                  const NewAppButton(),
                ],
              ),
            ),
          ),
        ));
  }

  // bind the function passed by ooutter with the bloc listener
  List<BlocListener<MenuBloc, MenuState>> bind() {
    return [
      BlocListener<MenuBloc, MenuState>(
        listenWhen: (p, c) => p.pageContext != c.pageContext,
        listener: (context, state) => pageContextChanged(state.pageContext),
      ),
      BlocListener<MenuBloc, MenuState>(
        listenWhen: (p, c) => p.isCollapse != c.isCollapse,
        listener: (context, state) => isCollapseChanged(state.isCollapse),
      )
    ];
  }
}

class MenuTopBar extends StatelessWidget {
  const MenuTopBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return SizedBox(
          height: HomeSizes.menuTopBarHeight,
          child: Row(
            children: [
              const Text(
                'AppFlowy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ).constrained(minWidth: 100),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () =>
                    context.read<MenuBloc>().add(const MenuEvent.collapse()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NewAppButton extends StatelessWidget {
  const NewAppButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeSizes.menuAddButtonHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.add),
          const SizedBox(
            width: 10,
          ),
          TextButton(
            onPressed: () async {
              // Dialogs.show(OkCancelDialog(
              //   title: "No Connection",
              //   message:
              //       "It appears your device is offline. Please check your connection and try again.",
              //   onOkPressed: () => AppGlobals.nav.pop(),
              // ));
            },
            child: const Text('New App',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          )
        ],
      ),
    );
  }
}
