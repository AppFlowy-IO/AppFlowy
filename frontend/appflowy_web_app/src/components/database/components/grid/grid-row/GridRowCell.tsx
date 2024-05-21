import { GridColumnType } from '../grid-column';
import React from 'react';
import GridCell from '../grid-cell/GridCell';

export interface GridRowCellProps {
  rowId: string;
  fieldId?: string;
  type: GridColumnType;
  columnIndex: number;
  rowIndex: number;
  onResize?: (rowIndex: number, columnIndex: number, size: { width: number; height: number }) => void;
}

export function GridRowCell({ onResize, rowIndex, columnIndex, rowId, fieldId, type }: GridRowCellProps) {
  if (type === GridColumnType.Field && fieldId) {
    return (
      <GridCell rowIndex={rowIndex} onResize={onResize} rowId={rowId} fieldId={fieldId} columnIndex={columnIndex} />
    );
  }

  if (type === GridColumnType.Action) {
    return null;
  }

  return null;
}

export default GridRowCell;
