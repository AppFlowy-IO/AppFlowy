import { BlockType } from '@/application/types';
import { EditorElementProps, SimpleTableNode, SimpleTableRowNode } from '@/components/editor/editor.type';
import { renderColor } from '@/utils/color';
import React, { forwardRef, useMemo } from 'react';
import { Editor, Element, NodeEntry } from 'slate';
import { ReactEditor, useSlate } from 'slate-react';

const SimpleTableRow =
  forwardRef<HTMLTableRowElement, EditorElementProps<SimpleTableRowNode>>(({
      node,
      children,
      ...attributes
    }, ref) => {
      const { blockId } = node;
      const editor = useSlate();
      const path = ReactEditor.findPath(editor, node);

      const parent = useMemo(() => {
        const match = Editor.above(editor, {
          match: (n) => {
            return !Editor.isEditor(n) && Element.isElement(n) && n.type === BlockType.SimpleTableBlock;
          },
          at: path,
        });

        if (!match) return null;

        return match as NodeEntry<Element>;
      }, [editor, path]);

      const index = useMemo(() => {
        if (!parent) return 0;

        const [parentElement] = parent;

        return (parentElement.children as Element[]).findIndex((n) => n.blockId === node.blockId);
      }, [node, parent]);

      const { align, bgColor } = useMemo(() => {
        if (!parent) return {
          align: undefined,
          bgColor: undefined,
        };

        const [parentElement] = parent;

        return {
          align: (parentElement as SimpleTableNode).data.row_aligns?.[index],
          bgColor: (parentElement as SimpleTableNode).data.row_colors?.[index],
        };
      }, [index, parent]);

      return (
        <tr
          data-row-index={index}
          data-block-type={node.type}
          ref={ref}
          {...attributes}
          data-table-row={blockId}

          data-table-row-horizontal-align={align?.toLowerCase()}
          style={{
            ...attributes.style,
            backgroundColor: bgColor ? renderColor(bgColor) : undefined,
          }}
        >
          {children}
        </tr>
      );
    },
  );

export default SimpleTableRow;