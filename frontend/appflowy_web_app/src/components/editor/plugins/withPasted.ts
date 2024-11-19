import { YjsEditor } from '@/application/slate-yjs';
import { slateContentInsertToYData } from '@/application/slate-yjs/utils/convert';
import { beforePasted } from '@/application/slate-yjs/utils/slateUtils';
import {
  assertDocExists,
  getBlock,
  getBlockEntry,
  getChildrenArray,
  getSharedRoot,
} from '@/application/slate-yjs/utils/yjsOperations';
import { MentionType, YjsEditorKey } from '@/application/types';
import { deserializeHTML } from '@/components/editor/utils/fragment';
import { BasePoint, Node, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';
import isURL from 'validator/lib/isURL';

export const withPasted = (editor: ReactEditor) => {

  editor.insertTextData = (data: DataTransfer) => {
    if (!beforePasted(editor))
      return false;
    const text = data.getData('text/plain');

    if (text) {

      const lines = text.split(/\r\n|\r|\n/);

      console.log('insertTextData', {
        lines,
      });
      if (lines.filter(Boolean).length > 1) {
        return insertHtmlData(editor, data);
      }

      const isUrl = isURL(text, {
        host_whitelist: ['localhost', 'appflowy.com', '*.appflowy.com'],
      });

      console.log('insertTextData', {
        text, isUrl,
      });

      if (isUrl) {
        const url = new URL(text);
        const blockId = url.searchParams.get('blockId');

        if (blockId) {
          const pageId = url.pathname.split('/').pop();
          const point = editor.selection?.anchor as BasePoint;

          Transforms.insertNodes(editor, {
            text: '@', mention: {
              type: MentionType.PageRef,
              page_id: pageId,
              block_id: blockId,
            },
          }, { at: point, select: true, voids: false });

        }

        return true;
      }

      for (const line of lines) {
        const point = editor.selection?.anchor as BasePoint;

        if (line) {
          Transforms.insertNodes(editor, { text: line }, { at: point, select: true, voids: false });
        }
      }

      return true;
    }

    return false;
  };

  editor.insertFragment = (fragment, options = {}) => {
    return insertFragment(editor, fragment, options);
  };

  return editor;
};

function insertHtmlData (editor: ReactEditor, data: DataTransfer) {
  const html = data.getData('text/html');

  if (html) {
    console.log('insert HTML Data', html);
    const fragment = deserializeHTML(html) as Node[];

    insertFragment(editor, fragment);

    return true;
  }

  return false;
}

function insertFragment (editor: ReactEditor, fragment: Node[], options = {}) {
  console.log('insertFragment', fragment, options);
  if (!beforePasted(editor))
    return;

  const point = editor.selection?.anchor as BasePoint;
  const [node] = getBlockEntry(editor as YjsEditor, point);
  const blockId = node.blockId as string;
  const sharedRoot = getSharedRoot(editor as YjsEditor);
  const block = getBlock(blockId, sharedRoot);
  const parent = getBlock(block.get(YjsEditorKey.block_parent), sharedRoot);
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
  const index = parentChildren.toArray().findIndex((id) => id === block.get(YjsEditorKey.block_id));
  const doc = assertDocExists(sharedRoot);

  doc.transact(() => {
    slateContentInsertToYData(block.get(YjsEditorKey.block_parent), index + 1, fragment, doc);
  });

  Transforms.move(editor, {
    distance: 1,
    unit: 'line',
  });

  return;
}