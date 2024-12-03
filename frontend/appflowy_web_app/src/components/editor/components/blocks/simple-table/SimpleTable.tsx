import { EditorElementProps, SimpleTableNode, SimpleTableRowNode } from '@/components/editor/editor.type';
import { useEditorContext } from '@/components/editor/EditorContext';
import TableContainer from '@/components/editor/components/table-container/TableContainer';
import isEqual from 'lodash-es/isEqual';
import React, { forwardRef, memo, useMemo } from 'react';
import './simple-table.scss';

const MIN_WIDTH = 120;

const SimpleTable = memo(
  forwardRef<HTMLDivElement, EditorElementProps<SimpleTableNode>>(({
    node,
    children,
    className: classNameProp,
    ...attributes
  }, ref) => {
    const context = useEditorContext();
    const readSummary = context.readSummary;
    const { data, blockId, children: rows } = node;
    const { column_widths, column_colors, enable_header_column, enable_header_row } = data;

    const columnCount = useMemo(() => {
      const firstRow = rows[0] as SimpleTableRowNode;

      if (!firstRow) return 0;

      return firstRow.children.length;
    }, [rows]);

    const columns = useMemo(() => {
      return Array.from({ length: columnCount }, (_, index) => {
        const width = column_widths[index] || MIN_WIDTH;
        const bgColor = column_colors[index] || 'transparent';

        return { width, bgColor };
      });
    }, [columnCount, column_colors, column_widths]);
    const colGroup = useMemo(() => {
      if (!columns) return null;
      return <colgroup>
        {columns.map((column, index) => (
          <col
            key={index}
            style={{ width: `${column.width}px` }}
          />
        ))}
      </colgroup>;
    }, [columns]);

    const className = useMemo(() => {
      const classList = ['simple-table', 'appflowy-scroller'];

      if (classNameProp) {
        classList.push(classNameProp);
      }

      if (enable_header_column) {
        classList.push('enable-header-column');
      }

      if (enable_header_row) {
        classList.push('enable-header-row');
      }

      return classList.join(' ');
    }, [classNameProp, enable_header_column, enable_header_row]);

    return (
      <div
        ref={ref}
        {...attributes}
        className={className}
      >
        <TableContainer
          blockId={blockId}
          readSummary={readSummary}
        >
          <table>
            {colGroup}
            <tbody>
            {children}
            </tbody>
          </table>
        </TableContainer>
      </div>
    );
  }),
  (prevProps, nextProps) => isEqual(prevProps.node, nextProps.node),
);

export default SimpleTable;