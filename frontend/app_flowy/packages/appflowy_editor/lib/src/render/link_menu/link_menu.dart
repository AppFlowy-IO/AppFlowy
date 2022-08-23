import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';

class LinkMenu extends StatefulWidget {
  const LinkMenu({
    Key? key,
    this.linkText,
    required this.onSubmitted,
    required this.onCopyLink,
    required this.onRemoveLink,
  }) : super(key: key);

  final String? linkText;
  final void Function(String text) onSubmitted;
  final VoidCallback onCopyLink;
  final VoidCallback onRemoveLink;

  @override
  State<LinkMenu> createState() => _LinkMenuState();
}

class _LinkMenuState extends State<LinkMenu> {
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _textEditingController.text = widget.linkText ?? '';
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16.0),
              _buildInput(),
              const SizedBox(height: 16.0),
              if (widget.linkText != null) ...[
                _buildIconButton(
                  iconName: 'link',
                  text: 'Copy link',
                  onPressed: widget.onCopyLink,
                ),
                _buildIconButton(
                  iconName: 'delete',
                  text: 'Remove link',
                  onPressed: widget.onRemoveLink,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Add your link',
      style: TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInput() {
    return TextField(
      focusNode: _focusNode,
      style: const TextStyle(fontSize: 14.0),
      textAlign: TextAlign.left,
      controller: _textEditingController,
      onSubmitted: widget.onSubmitted,
      decoration: const InputDecoration(
        hintText: 'URL',
        hintStyle: TextStyle(fontSize: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: Color(0xFFBDBDBD)),
        ),
        contentPadding: EdgeInsets.all(16.0),
        isDense: true,
      ),
    );
  }

  Widget _buildIconButton({
    required String iconName,
    required String text,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      icon: FlowySvg(name: iconName),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
      label: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14.0,
        ),
      ),
      onPressed: onPressed,
    );
  }
}
