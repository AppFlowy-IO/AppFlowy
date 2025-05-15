import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class ShareWithUserWidget extends StatefulWidget {
  const ShareWithUserWidget({super.key});

  @override
  State<ShareWithUserWidget> createState() => _ShareWithUserWidgetState();
}

class _ShareWithUserWidgetState extends State<ShareWithUserWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: AFTextField(
            controller: _controller,
            size: AFTextFieldSize.m,
            hintText: 'Invite by email',
          ),
        ),
        HSpace(theme.spacing.s),
        _isButtonEnabled
            ? AFFilledTextButton.primary(
                text: 'Invite',
                onTap: () {},
              )
            : AFFilledTextButton.disabled(
                text: 'Invite',
              ),
      ],
    );
  }

  void _onTextChanged() {
    setState(() {
      _isButtonEnabled = _controller.text.trim().isNotEmpty;
    });
  }
}
