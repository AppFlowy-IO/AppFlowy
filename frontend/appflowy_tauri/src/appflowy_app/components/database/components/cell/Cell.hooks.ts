import { useCallback, useEffect, useState } from 'react';
import { DatabaseNotification } from '@/services/backend';
import { useNotification, useViewId } from '$app/hooks';
import { cellService, Cell, Field } from '$app/application/database';
import { useDispatchCell, useSelectorCell } from '$app/components/database';

export const useCell = (rowId: string, field: Field) => {
  const viewId = useViewId();
  const { setCell } = useDispatchCell();
  const [loading, setLoading] = useState(false);
  const cell = useSelectorCell(rowId, field.id);

  const fetchCell = useCallback(() => {
    setLoading(true);
    void cellService.getCell(viewId, rowId, field.id, field.type).then((data) => {
      // cache cell
      setCell(data);
      setLoading(false);
    });
  }, [viewId, rowId, field.id, field.type, setCell]);

  useEffect(() => {
    // fetch cell if not cached
    if (!cell && !loading) {
      // fetch cell in next tick to avoid blocking
      const timeout = setTimeout(fetchCell, 0);

      return () => {
        clearTimeout(timeout);
      };
    }
  }, [fetchCell, cell, loading, rowId, field.id]);

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
