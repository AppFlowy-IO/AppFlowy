import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/view_lock_status_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LockPageAction extends StatefulWidget {
  const LockPageAction({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<LockPageAction> createState() => _LockPageActionState();
}

class _LockPageActionState extends State<LockPageAction> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ViewLockStatusBloc(view: widget.view),
      child: BlocConsumer<ViewLockStatusBloc, ViewLockStatusState>(
        listener: (context, state) {
          if (state.isLocked) {
            showToastNotification(
              context,
              // todo: i18n
              message:
                  'Page locked. Editing is disabled until someone unlocks it.',
            );
          }
        },
        builder: (context, state) {
          return _buildTextButton(
            context,
            isLocked: state.isLocked,
          );
        },
      ),
    );
  }

  Widget _buildTextButton(
    BuildContext context, {
    required bool isLocked,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: FlowyIconTextButton(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        onTap: () => _toggle(context),
        leftIconBuilder: (onHover) => FlowySvg(
          FlowySvgs.lock_page_s,
          size: const Size.square(16.0),
        ),
        iconPadding: 10.0,
        textBuilder: (onHover) => FlowyText(
          LocaleKeys.disclosureAction_lockPage.tr(),
          figmaLineHeight: 18.0,
        ),
        rightIconBuilder: (_) => _buildSwitch(
          context,
          isLocked: isLocked,
        ),
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required bool isLocked,
  }) {
    return Container(
      width: 30,
      height: 20,
      margin: const EdgeInsets.only(right: 6),
      child: FittedBox(
        fit: BoxFit.fill,
        child: CupertinoSwitch(
          value: isLocked,
          activeTrackColor: Theme.of(context).colorScheme.primary,
          onChanged: (_) => _toggle(context),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final isLocked = context.read<ViewLockStatusBloc>().state.isLocked;

    context.read<ViewLockStatusBloc>().add(
          isLocked ? ViewLockStatusEvent.unlock() : ViewLockStatusEvent.lock(),
        );

    Log.info('update page(${widget.view.id}) lock status: $isLocked');
  }
}
