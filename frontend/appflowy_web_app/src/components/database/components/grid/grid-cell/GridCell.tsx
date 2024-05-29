import { FieldId, YjsDatabaseKey } from '@/application/collab.type';
import { useCellSelector } from '@/application/database-yjs';
import { useFieldSelector } from '@/application/database-yjs/selector';
import { Cell } from '@/components/database/components/cell';
import { CellProps, Cell as CellType } from '@/components/database/components/cell/cell.type';
import { PrimaryCell } from '@/components/database/components/cell/primary';
import React, { useEffect, useMemo, useRef } from 'react';

export interface GridCellProps {
  rowId: string;
  fieldId: FieldId;
  columnIndex: number;
  rowIndex: number;
  onResize?: (rowIndex: number, columnIndex: number, size: { width: number; height: number }) => void;
}

export function GridCell({ onResize, rowId, fieldId, columnIndex, rowIndex }: GridCellProps) {
  const ref = useRef<HTMLDivElement>(null);
  const { field } = useFieldSelector(fieldId);
  const isPrimary = field?.get(YjsDatabaseKey.is_primary);
  const cell = useCellSelector({
    rowId,
    fieldId,
  });

  useEffect(() => {
    const el = ref.current;

    if (!el || !cell) return;

    const observer = new ResizeObserver(() => {
      onResize?.(rowIndex, columnIndex, {
        width: el.offsetWidth,
        height: el.offsetHeight,
      });
    });

    observer.observe(el);

    return () => {
      observer.disconnect();
    };
  }, [columnIndex, onResize, rowIndex, cell]);

  const Component = useMemo(() => {
    if (isPrimary) {
      return PrimaryCell;
    }

    return Cell;
  }, [isPrimary]) as React.FC<CellProps<CellType>>;

  if (!field) return null;

  return (
    <div ref={ref} className={'grid-cell flex min-h-full w-full cursor-text items-center overflow-hidden text-xs'}>
      <Component cell={cell} rowId={rowId} fieldId={fieldId} />
    </div>
  );
}

export default GridCell;
