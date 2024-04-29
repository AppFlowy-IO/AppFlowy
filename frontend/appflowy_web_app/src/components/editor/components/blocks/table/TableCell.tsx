import { EditorElementProps, TableCellNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

const TableCell = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TableCellNode>>(
    ({ node: _, children, className, ...attributes }, ref) => {
      return (
        <div ref={ref} {...attributes} className={`relative table-cell text-left ${className || ''}`}>
          {children}
        </div>
      );
    }
  )
);

export default TableCell;
