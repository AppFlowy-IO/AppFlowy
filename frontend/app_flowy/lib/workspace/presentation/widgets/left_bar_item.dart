import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:app_flowy/workspace/application/view/view_service.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class ViewLeftBarItem extends StatefulWidget {
  final ViewPB view;

  ViewLeftBarItem({required this.view, Key? key})
      : super(key: ValueKey(view.hashCode));

  @override
  State<ViewLeftBarItem> createState() => _ViewLeftBarItemState();
}

class _ViewLeftBarItemState extends State<ViewLeftBarItem> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late ViewService _viewService;
  late ViewListener _viewListener;
  late ViewPB view;

  @override
  void initState() {
    view = widget.view;
    _viewService = ViewService();
    _focusNode.addListener(_handleFocusChanged);
    _viewListener = ViewListener(view: widget.view);
    _viewListener.start(onViewUpdated: (result) {
      result.fold(
        (updatedView) {
          if (mounted) {
            setState(() => view = updatedView);
          }
        },
        (err) => Log.error(err),
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _viewListener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.text = view.name;

    return IntrinsicWidth(
      key: ValueKey(_controller.text),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        scrollPadding: EdgeInsets.zero,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          isDense: true,
        ),
        style: TextStyles.body1.size(FontSizes.s14),
        // cursorColor: widget.cursorColor,
        // obscureText: widget.enableObscure,
      ),
    );
  }

  void _handleFocusChanged() {
    if (_controller.text.isEmpty) {
      _controller.text = view.name;
      return;
    }

    if (_controller.text != view.name) {
      _viewService.updateView(viewId: view.id, name: _controller.text);
    }
  }
}
