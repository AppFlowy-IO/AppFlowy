import { useCallback, useEffect, useState } from 'react';
import { DatabaseNotification, FieldType } from '@/services/backend';
import { useNotification, useViewId } from '$app/hooks';
import { cellService, Cell } from '../../application';

export const useCell = (rowId: string, fieldId: string, fieldType: FieldType) => {
  const viewId = useViewId();
  const [cell, setCell] = useState<Cell | undefined>(undefined);

  const fetchCell = useCallback(() => {
    void cellService.getCell(viewId, rowId, fieldId, fieldType).then((data) => {
      setCell(data);
    });
  }, [viewId, rowId, fieldId, fieldType]);

  useEffect(() => {
    fetchCell();
  }, [fetchCell]);

  useNotification(DatabaseNotification.DidUpdateCell, fetchCell, { id: `${rowId}:${fieldId}` });

  return cell;
};
