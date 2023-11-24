import { useCallback, useEffect, useState } from 'react';
import { DatabaseNotification } from '@/services/backend';
import { useNotification, useViewId } from '$app/hooks';
import { cellService, Cell, Field } from '../../application';

export const useCell = (rowId: string, field: Field) => {
  const viewId = useViewId();
  const [cell, setCell] = useState<Cell | undefined>(undefined);

  const fetchCell = useCallback(() => {
    void cellService.getCell(viewId, rowId, field.id, field.type).then((data) => {
      setCell(data);
    });
  }, [viewId, rowId, field]);

  useEffect(() => {
    fetchCell();
  }, [fetchCell]);

  useNotification(DatabaseNotification.DidUpdateCell, fetchCell, { id: `${rowId}:${field.id}` });

  return cell;
};

export const useInputCell = (cell?: Cell) => {
  const [editing, setEditing] = useState(false);
  const [value, setValue] = useState('');
  const viewId = useViewId();
  const updateCell = useCallback(() => {
    if (!cell) return;
    const { rowId, fieldId } = cell;

    if (editing) {
      if (value !== cell.data) {
        void cellService.updateCell(viewId, rowId, fieldId, value);
      }

      setEditing(false);
    }
  }, [cell, editing, value, viewId]);

  return {
    updateCell,
    editing,
    setEditing,
    value,
    setValue,
  };
};
