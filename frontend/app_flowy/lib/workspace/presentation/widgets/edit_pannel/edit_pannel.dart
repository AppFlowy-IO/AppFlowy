import 'package:app_flowy/workspace/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/workspace/application/edit_pannel/edit_context.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/bar_title.dart';
import 'package:flowy_infra_ui/style_widget/close_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class EditPannel extends StatelessWidget {
  final EditPannelContext pannelContext;
  final VoidCallback onEndEdit;
  const EditPannel({
    Key? key,
    required this.pannelContext,
    required this.onEndEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.secondary,
      child: BlocProvider(
        create: (context) => getIt<EditPannelBloc>(),
        child: BlocBuilder<EditPannelBloc, EditPannelState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EditPannelTopBar(onClose: () => onEndEdit()),
                Expanded(
                  child: pannelContext.child,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class EditPannelTopBar extends StatelessWidget {
  final VoidCallback onClose;
  const EditPannelTopBar({Key? key, required this.onClose}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeSizes.editPannelTopBarHeight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            FlowyBarTitle(
              title: LocaleKeys.title.tr(),
            ),
            const Spacer(),
            FlowyCloseButton(onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
