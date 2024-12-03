import { BlockType, TableAlignType } from '@/application/types';
import { EditorElementProps, SimpleTableCellBlockNode, SimpleTableNode } from '@/components/editor/editor.type';
import { renderColor } from '@/utils/color';
import React, { forwardRef, useMemo } from 'react';
import { Editor, Element, NodeEntry } from 'slate';
import { ReactEditor, useSlate } from 'slate-react';

const SimpleTableCell =
  forwardRef<HTMLTableCellElement, EditorElementProps<SimpleTableCellBlockNode>>(({
      node,
      children,
      ...attributes
    }, ref) => {
      const { blockId } = node;
      const editor = useSlate();
      const path = ReactEditor.findPath(editor, node);

      const table = useMemo(() => {
        const match = Editor.above(editor, {
          match: (n) => {
            return !Editor.isEditor(n) && Element.isElement(n) && n.type === BlockType.SimpleTableBlock;
          },
          at: path,
        });

        if (!match) return null;

        return match as NodeEntry<Element>;
      }, [editor, path]);

      const row = useMemo(() => {
        const match = Editor.above(editor, {
          match: (n) => {
            return !Editor.isEditor(n) && Element.isElement(n) && n.type === BlockType.SimpleTableRowBlock;
          },
          at: path,
        });

        if (!match) return null;

        return match as NodeEntry<Element>;
      }, [editor, path]);

      const colIndex = useMemo(() => {
        if (!row) return 0;

        const [parentElement] = row;

        return (parentElement.children as Element[]).findIndex((n) => n.blockId === node.blockId);
      }, [node, row]);

      const { horizontalAlign, bgColor } = useMemo(() => {
        if (!table || !row) return {
          bgColor: '',
          horizontalAlign: TableAlignType.Left,
        };

        const [parentElement] = table;

        const horizontalAlign = (parentElement as SimpleTableNode).data.column_aligns[colIndex];
        const bgColor = (parentElement as SimpleTableNode).data.column_colors[colIndex];

        return {
          horizontalAlign,
          bgColor,
        };
      }, [colIndex, row, table]);

      return (
        <td
          data-block-type={node.type}
          data-block-cell={blockId}
          data-cell-index={colIndex}
          ref={ref}
          {...attributes}
          rowSpan={1}
          colSpan={1}
          data-table-cell-horizontal-align={horizontalAlign?.toLowerCase()}
          style={{
            ...attributes.style,
            backgroundColor: bgColor ? renderColor(bgColor) : undefined,
          }}
        >
          <div className={'cell-children'}>
            {children}
          </div>
        </td>
      );
    },
  );

export default SimpleTableCell;