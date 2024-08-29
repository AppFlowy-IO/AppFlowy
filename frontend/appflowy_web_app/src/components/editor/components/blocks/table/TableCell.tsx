import { EditorElementProps, TableCellNode } from '@/components/editor/editor.type';
import { renderColor } from '@/utils/color';
import React, { forwardRef, memo } from 'react';

const TableCell = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TableCellNode>>(({ node, children, className, ...attributes }, ref) => {
    const { data } = node;
    const rowBackgroundColor = data.rowBackgroundColor;
    const colBackgroundColor = data.colBackgroundColor;

    return (
      <div
        ref={ref}
        {...attributes}
        style={{
          fontSize: '15px',
          ...attributes.style,
          backgroundColor:
            rowBackgroundColor || colBackgroundColor ? renderColor(colBackgroundColor || rowBackgroundColor) : undefined,
        }}
        className={`relative px-1 table-cell text-left ${className || ''}`}
      >
        {children}
      </div>
    );
  }),
);

export default TableCell;
