import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/plugin/AI/gpt3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ToolbarItem smartEditItem = ToolbarItem(
  id: 'appflowy.toolbar.smart_edit',
  type: 5,
  iconBuilder: (isHighlight) {
    return Icon(
      Icons.edit,
      color: isHighlight ? Colors.lightBlue : Colors.white,
      size: 14,
    );
  },
  validator: (editorState) {
    final nodes = editorState.service.selectionService.currentSelectedNodes;
    return nodes.whereType<TextNode>().length == nodes.length &&
        1 == nodes.length;
  },
  highlightCallback: (_) => false,
  tooltipsMessage: 'Smart Edit',
  handler: (editorState, context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SmartEditWidget(
            editorState: editorState,
          ),
        );
      },
    );
  },
);

class SmartEditWidget extends StatefulWidget {
  const SmartEditWidget({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  State<SmartEditWidget> createState() => _SmartEditWidgetState();
}

class _SmartEditWidgetState extends State<SmartEditWidget> {
  final inputEventController = TextEditingController(text: '');
  final resultController = TextEditingController(text: '');

  var result = '';

  final gpt3 = const GPT3APIClient(apiKey: apiKey);

  Iterable<TextNode> get currentSelectedTextNodes =>
      widget.editorState.service.selectionService.currentSelectedNodes
          .whereType<TextNode>();
  Selection? get currentSelection =>
      widget.editorState.service.selectionService.currentSelection.value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RawKeyboardListener(
            focusNode: FocusNode(),
            child: TextField(
              autofocus: true,
              controller: inputEventController,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe how you\'d like AppFlowy to edit this text',
              ),
            ),
            onKey: (key) {
              if (key is! RawKeyDownEvent) return;
              if (key.logicalKey == LogicalKeyboardKey.enter) {
                _requestGPT3EditResult();
              } else if (key.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
              }
            },
          ),
          if (result.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Result: ',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: TextField(
                controller: resultController..text = result,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'Describe how you\'d like AppFlowy to edit this text',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();

                    // replace the text
                    final selection = currentSelection;
                    if (selection != null) {
                      assert(selection.isSingle);
                      final transaction = widget.editorState.transaction;
                      transaction.replaceText(
                        currentSelectedTextNodes.first,
                        selection.startIndex,
                        selection.length,
                        resultController.text,
                      );
                      widget.editorState.apply(transaction);
                    }
                  },
                  child: const Text('Replace'),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  void _requestGPT3EditResult() {
    final selection =
        widget.editorState.service.selectionService.currentSelection.value;
    if (selection == null || !selection.isSingle) {
      return;
    }
    final text =
        widget.editorState.service.selectionService.currentSelectedNodes
            .whereType<TextNode>()
            .first
            .delta
            .slice(
              selection.startIndex,
              selection.endIndex,
            )
            .toPlainText();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Loading'),
            ],
          ),
        );
      },
    );

    gpt3.getGPT3Edit(
      apiKey,
      text,
      inputEventController.text,
      onResult: (result) async {
        Navigator.of(context).pop(true);
        setState(() {
          this.result = result.join('\n').trim();
        });
      },
      onError: () async {
        Navigator.of(context).pop(true);
      },
    );
  }
}
