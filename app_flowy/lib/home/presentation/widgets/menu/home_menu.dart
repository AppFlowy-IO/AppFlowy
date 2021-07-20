import 'package:app_flowy/home/application/menu/menu_bloc.dart';
import 'package:app_flowy/home/domain/page_context.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/startup/tasks/app_widget_task.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/styled_text_input.dart';
import 'package:flowy_infra_ui/widget/buttons/ok_cancel_button.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home_sizes.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

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
    return BlocProvider(
      create: (context) => getIt<MenuBloc>(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.pageContext != c.pageContext,
            listener: (context, state) => pageContextChanged(state.pageContext),
          ),
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.isCollapse != c.isCollapse,
            listener: (context, state) => isCollapseChanged(state.isCollapse),
          )
        ],
        child: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) => _renderBody(context),
        ),
      ),
    );
  }

  Widget _renderBody(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const MenuTopBar(),
          Expanded(child: Container()),
          NewAppButton(
            createAppCallback: (appName) =>
                context.read<MenuBloc>().add(MenuEvent.createApp(appName)),
          ),
        ],
      ).padding(horizontal: Insets.sm),
    );
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
  final Function(String)? createAppCallback;

  const NewAppButton({this.createAppCallback, Key? key}) : super(key: key);
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
            onPressed: () async => await _showCreateAppDialog(context),
            child: _buttonTitle(),
          )
        ],
      ),
    );
  }

  Widget _buttonTitle() {
    return const Text('New App',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ));
  }

  Future<void> _showCreateAppDialog(BuildContext context) async {
    await Dialogs.showWithContext(CreateAppDialogContext(
      confirm: (appName) {
        if (appName.isNotEmpty && createAppCallback != null) {
          createAppCallback!(appName);
        }
      },
    ), context);
  }
}

//ignore: must_be_immutable
class CreateAppDialogContext extends DialogContext {
  String appName;
  final Function(String)? confirm;

  CreateAppDialogContext({this.appName = "", this.confirm})
      : super(identifier: 'CreateAppDialogContext');

  @override
  Widget buildWiget(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return StyledDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...[
            Text('Create App'.toUpperCase(),
                style: TextStyles.T1.textColor(theme.accent1Darker)),
            VSpace(Insets.sm * 1.5),
            // Container(color: theme.greyWeak.withOpacity(.35), height: 1),
            VSpace(Insets.m * 1.5),
          ],
          StyledFormTextInput(
            hintText: "App name",
            onChanged: (text) {
              appName = text;
            },
          ),
          SizedBox(height: Insets.l),
          OkCancelButton(
            onOkPressed: () {
              if (confirm != null) {
                confirm!(appName);
                AppGlobals.nav.pop();
              }
            },
            onCancelPressed: () {
              AppGlobals.nav.pop();
            },
          )
        ],
      ),
    );
  }

  @override
  List<Object> get props => [identifier];

  @override
  bool get barrierDismissable => false;
}
