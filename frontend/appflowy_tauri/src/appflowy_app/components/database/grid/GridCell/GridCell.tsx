import React, { CSSProperties, memo } from 'react';
import { GridColumn, RenderRow, RenderRowType } from '../constants';
import GridNewRow from '$app/components/database/grid/GridNewRow/GridNewRow';
import GridCalculate from '$app/components/database/grid/GridCalculate/GridCalculate';
import { areEqual } from 'react-window';
import { Cell } from '$app/components/database/components';
import PrimaryCell from '$app/components/database/grid/GridCell/PrimaryCell';

const getRenderRowKey = (row: RenderRow) => {
  if (row.type === RenderRowType.Row) {
    return `row:${row.data.meta.id}`;
  }

  return row.type;
};

interface GridCellProps {
  row: RenderRow;
  column: GridColumn;
  columnIndex: number;
  style: CSSProperties;
  onEditRecord?: (rowId: string) => void;
  getContainerRef?: () => React.RefObject<HTMLDivElement>;
}

export const GridCell = memo(({ row, column, columnIndex, style, onEditRecord, getContainerRef }: GridCellProps) => {
  const key = getRenderRowKey(row);

  const field = column.field;

  if (!field) return <div data-key={key} style={style} />;

  switch (row.type) {
    case RenderRowType.Row: {
      const renderRowCell = <Cell rowId={row.data.meta.id} icon={row.data.meta.icon} field={field} />;

      return (
        <div data-key={key} style={style} className={'grid-cell flex border-b border-r border-line-divider'}>
          {field.isPrimary ? (
            <PrimaryCell
              icon={row.data.meta.icon}
              onEditRecord={onEditRecord}
              getContainerRef={getContainerRef}
              rowId={row.data.meta.id}
            >
              {renderRowCell}
            </PrimaryCell>
          ) : (
            renderRowCell
          )}
        </div>
      );
    }

    case RenderRowType.NewRow:
      return (
        <div style={style} className={'flex border-b border-line-divider'}>
          <GridNewRow
            getContainerRef={getContainerRef}
            index={columnIndex}
            startRowId={row.data.startRowId}
            groupId={row.data.groupId}
          />
        </div>
      );
    case RenderRowType.CalculateRow:
      return (
        <div className={'flex'} style={style}>
          <GridCalculate getContainerRef={getContainerRef} field={field} index={columnIndex} />
        </div>
      );
    default:
      return null;
  }
}, areEqual);
