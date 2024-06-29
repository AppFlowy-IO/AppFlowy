import { AFScroller } from '@/components/_shared/scroller';
import { EditorElementProps, TableCellNode, TableNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useMemo } from 'react';
import { Grid } from '@atlaskit/primitives';
import './table.scss';
import isEqual from 'lodash-es/isEqual';

const Table = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TableNode>>(({ node, children, className, ...attributes }, ref) => {
    const { rowsLen, colsLen, rowDefaultHeight, colsHeight } = node.data;
    const cells = node.children as TableCellNode[];

    const columnGroup = useMemo(() => {
      return Array.from({ length: colsLen }, (_, index) => {
        return cells.filter((cell) => cell.data.colPosition === index);
      });
    }, [cells, colsLen]);

    const rowGroup = useMemo(() => {
      return Array.from({ length: rowsLen }, (_, index) => {
        return cells.filter((cell) => cell.data.rowPosition === index);
      });
    }, [cells, rowsLen]);

    const templateColumns = useMemo(() => {
      return columnGroup
        .map((group) => {
          return `${group[0].data.width || colsHeight}px`;
        })
        .join(' ');
    }, [colsHeight, columnGroup]);

    const templateRows = useMemo(() => {
      return rowGroup
        .map((group) => {
          return `${group[0].data.height || rowDefaultHeight}px`;
        })
        .join(' ');
    }, [rowGroup, rowDefaultHeight]);

    return (
      <div
        ref={ref}
        {...attributes}
        className={`table-block relative my-2 w-full overflow-hidden px-1 ${className || ''}`}
      >
        <div className={'h-full w-full overflow-x-auto  overflow-y-hidden'}>
          <Grid
            id={`table-${node.blockId}`}
            rowGap='space.0'
            autoFlow='column'
            columnGap='space.0'
            templateRows={templateRows}
            templateColumns={templateColumns}
          >
            {children}
          </Grid>
        </div>
      </div>
    );
  }),
  (prevProps, nextProps) => isEqual(prevProps.node, nextProps.node)
);

export default Table;
