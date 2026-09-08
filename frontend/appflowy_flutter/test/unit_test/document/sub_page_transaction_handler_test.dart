import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_transaction_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds sub-page references in nested nodes', () {
    final root = Node(
      type: 'page',
      children: [
        Node(
          type: 'column',
          children: [
            Node(
              type: SubPageBlockKeys.type,
              attributes: {SubPageBlockKeys.viewId: 'page-id'},
            ),
          ],
        ),
      ],
    );

    expect(documentContainsSubPageReference(root, 'page-id'), isTrue);
    expect(documentContainsSubPageReference(root, 'other-page'), isFalse);
  });
}
