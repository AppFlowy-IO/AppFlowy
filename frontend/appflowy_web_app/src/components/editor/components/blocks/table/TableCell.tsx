import { EditorElementProps, TableCellNode } from '@/components/editor/editor.type';
import { renderColor } from '@/utils/color';
import React, { forwardRef, memo } from 'react';

const TableCell = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TableCellNode>>(({ node, children, className, ...attributes }, ref) => {
    const { data } = node;
    const rowBackgroundColor = data.rowBackgroundColor;

    return (
      <div
        ref={ref}
        {...attributes}
        style={{
          ...attributes.style,
          backgroundColor: rowBackgroundColor ? renderColor(data.rowBackgroundColor) : undefined,
        }}
        className={`relative table-cell text-left ${className || ''}`}
      >
        {children}
      </div>
    );
  })
);

export default TableCell;
