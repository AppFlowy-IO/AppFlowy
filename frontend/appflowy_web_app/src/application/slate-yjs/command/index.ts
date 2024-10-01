import { YjsEditor } from '@/application/slate-yjs/plugins/withYjs';
import {
  createBlock,
  getBlock,
  getChildrenArray,
  getText,
  updateBlockParent,
} from '@/application/slate-yjs/utils/common';
import { slatePointToRelativePosition } from '@/application/slate-yjs/utils/positions';
import { InlineBlockType, Mention, MentionType, YjsEditorKey } from '@/application/types';
import { FormulaNode } from '@/components/editor/editor.type';
import { renderDate } from '@/utils/time';
import Delta, { Op } from 'quill-delta';
import { BaseRange, Editor, Element, Node, NodeEntry, Range, Text, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';
import * as Y from 'yjs';

export const CustomEditor = {
  findTextNode (editor: ReactEditor, path: number[]): NodeEntry<Element> {
    const [node] = editor.nodes({
      at: path,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
    });

    return node as NodeEntry<Element>;
  },
  // Get the text content of a block node, including the text content of its children and formula nodes
  getBlockTextContent (node: Node): string {
    if (Element.isElement(node)) {
      if (node.type === InlineBlockType.Formula) {
        return (node as FormulaNode).data || '';
      }

      if (node.type === InlineBlockType.Mention && (node.data as Mention)?.type === MentionType.Date) {
        const date = (node.data as Mention).date || '';
        const isUnix = date?.length === 10;

        return renderDate(date, 'MMM DD, YYYY', isUnix);
      }
    }

    if (Text.isText(node)) {
      if (node.formula) {
        return node.formula;
      }

      if (node.mention) {
        if (node.mention.type === MentionType.Date) {
          const date = node.mention.date || '';
          const isUnix = date?.length === 10;

          return renderDate(date, 'MMM DD, YYYY', isUnix);
        } else {
          const name = document.querySelector('[data-mention-id="' + node.mention.page_id + '"]')?.textContent || '';

          return name;
        }
      }

      return node.text || '';
    }

    return node.children.map((n) => CustomEditor.getBlockTextContent(n)).join('');
  },

  // Insert break line at the specified path
  insertBreak (editor: YjsEditor, at?: BaseRange) {
    const sharedRoot = editor.sharedRoot;

    if (!sharedRoot || !sharedRoot.doc) {
      throw new Error('Shared root not found');
    }

    const newAt = at || editor.selection;

    if (!newAt) {
      throw new Error('Selection not found');
    }

    const startPoint = Editor.start(editor, newAt);
    const isCollapsed = Range.isCollapsed(newAt);
    const startRelativeRange = slatePointToRelativePosition(sharedRoot, editor, startPoint);
    const startTextId = startRelativeRange.entry[0].textId as string;
    const startPos = Y.createAbsolutePositionFromRelativePosition(
      startRelativeRange.point,
      sharedRoot.doc,
    );

    if (!startPos) {
      return;
    }

    if (isCollapsed) {
      const yText = getText(startTextId, sharedRoot);
      const relativeOffset = Math.min(startPos.index, yText.toJSON().length);

      const operations: (() => void)[] = [];

      operations.push(() => {
        yText.delete(relativeOffset, yText.length - relativeOffset);
      });

      const ops = yText.toDelta() as Op[];
      const delta = new Delta(ops);
      const nextLineDelta = delta.slice(relativeOffset);
      const blockSlateEntry = Editor.above(editor, {
        at: startPoint.path,
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
      });

      if (!blockSlateEntry) {
        throw new Error('Block not found');
      }

      const [blockNode] = blockSlateEntry as NodeEntry<Element>;
      const blockId = blockNode.blockId as string;
      const block = getBlock(blockId, sharedRoot);

      if (!block) {
        throw new Error('Block not found');
      }

      const parentId = block.get(YjsEditorKey.block_parent);
      const parent = getBlock(parentId, sharedRoot);

      if (!parent) {
        throw new Error('Parent block not found');
      }

      const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);
      const targetIndex = parentChildren.toArray().findIndex((id) => id === blockId);

      operations.push(() => {
        const newBlock = createBlock(sharedRoot, {
          ty: block.get(YjsEditorKey.block_type),
          data: {},
        });

        const blockText = getText(newBlock.get(YjsEditorKey.block_external_id), sharedRoot);

        blockText.applyDelta(nextLineDelta.ops);

        const index = targetIndex !== -1 ? targetIndex + 1 : parentChildren.length;

        updateBlockParent(sharedRoot, newBlock, parent, index);

      });

      console.time('insertBreak');
      sharedRoot.doc.transact(() => {
        operations.forEach((op) => op());
      });
      Transforms.move(editor, { distance: 1, unit: 'line' });
      console.timeEnd('insertBreak');

    }

  },
};
