import { FieldId, YjsDatabaseKey } from '@/application/collab.type';
import { useRowMeta } from '@/application/database-yjs';
import { useFieldSelector } from '@/application/database-yjs/selector';
import { Cell } from '@/components/database/components/cell';
import { parseYDatabaseCellToCell } from '@/components/database/components/cell/cell.parse';
import React, { useEffect, useState } from 'react';

export interface GridCellProps {
  rowId: string;
  fieldId: FieldId;
  columnIndex: number;
  rowIndex: number;
  onResize?: (rowIndex: number, columnIndex: number, size: { width: number; height: number }) => void;
}

export function GridCell({ onResize, rowId, fieldId, columnIndex, rowIndex }: GridCellProps) {
  const ref = React.useRef<HTMLDivElement>(null);
  const field = useFieldSelector(fieldId);
  const row = useRowMeta(rowId);
  const cell = row?.get(YjsDatabaseKey.cells)?.get(fieldId);
  const [cellValue, setCellValue] = useState(() => (cell ? parseYDatabaseCellToCell(cell) : undefined));

  useEffect(() => {
    if (!cell) return;
    setCellValue(parseYDatabaseCellToCell(cell));
    const observerEvent = () => setCellValue(parseYDatabaseCellToCell(cell));

    cell.observe(observerEvent);

    return () => {
      cell.unobserve(observerEvent);
    };
  }, [cell]);

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    const observer = new ResizeObserver(() => {
      if (onResize) {
        onResize(rowIndex, columnIndex, {
          width: el.offsetWidth,
          height: el.offsetHeight,
        });
      }
    });

    observer.observe(el);

    return () => {
      observer.disconnect();
    };
  }, [columnIndex, onResize, rowIndex]);

  if (!field) return null;
  return (
    <div ref={ref} className={'grid-cell w-full cursor-text overflow-hidden text-xs'}>
      <Cell cell={cellValue} rowId={rowId} fieldId={fieldId} />
    </div>
  );
}

export default GridCell;
