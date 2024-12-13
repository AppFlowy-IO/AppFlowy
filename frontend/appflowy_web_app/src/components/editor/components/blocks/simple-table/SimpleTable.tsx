import { useSimpleTable } from '@/components/editor/components/blocks/simple-table/SimpleTable.hooks';
import { EditorElementProps, SimpleTableNode, SimpleTableRowNode } from '@/components/editor/editor.type';
import { useEditorContext } from '@/components/editor/EditorContext';
import TableContainer from '@/components/editor/components/table-container/TableContainer';
import isEqual from 'lodash-es/isEqual';
import React, { forwardRef, memo, useMemo } from 'react';
import './simple-table.scss';
import { MIN_WIDTH } from '@/components/editor/components/blocks/simple-table/const';
// import { useReadOnly } from 'slate-react';

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
        const width = column_widths?.[index] || MIN_WIDTH;
        const bgColor = column_colors?.[index] || 'transparent';

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
    const { isIntersection } = useSimpleTable(node);

    const className = useMemo(() => {
      const classList = ['simple-table', 'appflowy-scroller', 'select-none'];

      if (classNameProp) {
        classList.push(classNameProp);
      }

      if (enable_header_column) {
        classList.push('enable-header-column');
      }

      if (enable_header_row) {
        classList.push('enable-header-row');
      }

      if (isIntersection) {
        classList.push('selected');
      }

      return classList.join(' ');
    }, [classNameProp, enable_header_column, enable_header_row, isIntersection]);

    // const readOnly = useReadOnly();

    return (
      <div
        ref={ref}
        {...attributes}
        className={className}
        contentEditable={false}
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