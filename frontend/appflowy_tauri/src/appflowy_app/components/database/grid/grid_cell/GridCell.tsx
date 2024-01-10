import React, { CSSProperties, memo } from 'react';
import { GridColumn, RenderRow, RenderRowType } from '../constants';
import GridNewRow from '$app/components/database/grid/grid_new_row/GridNewRow';
import { GridCalculate } from '$app/components/database/grid/grid_calculate';
import { areEqual } from 'react-window';
import { Cell } from '$app/components/database/components';
import { PrimaryCell } from '$app/components/database/grid/grid_cell';

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
      const { id: rowId, icon: rowIcon } = row.data.meta;
      const renderRowCell = <Cell rowId={rowId} icon={rowIcon} field={field} />;

      return (
        <div data-key={key} style={style} className={'grid-cell flex border-b border-r border-line-divider'}>
          {field.isPrimary ? (
            <PrimaryCell icon={rowIcon} onEditRecord={onEditRecord} getContainerRef={getContainerRef} rowId={rowId}>
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
          <GridNewRow getContainerRef={getContainerRef} index={columnIndex} groupId={row.data.groupId} />
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
