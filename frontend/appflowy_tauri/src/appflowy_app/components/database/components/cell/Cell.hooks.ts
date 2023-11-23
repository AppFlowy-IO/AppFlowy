import { useCallback, useEffect, useMemo, useState } from 'react';
import { DatabaseNotification, FieldType } from '@/services/backend';
import { useNotification, useViewId } from '$app/hooks';
import { cellService, Cell } from '../../application';
import { debounce } from 'lodash-es';

// delay for debounced fetch
// Because we don't want to fetch cell when element is scrolling
const DELAY = 200;

export const useCell = (rowId: string, fieldId: string, fieldType: FieldType) => {
  const viewId = useViewId();
  const [cell, setCell] = useState<Cell | undefined>(undefined);

  const fetchCell = useCallback(() => {
    void cellService.getCell(viewId, rowId, fieldId, fieldType).then((data) => {
      setCell(data);
    });
  }, [viewId, rowId, fieldId, fieldType]);

  const debouncedFetchCell = useMemo(() => debounce(fetchCell, DELAY), [fetchCell]);

  useEffect(() => {
    debouncedFetchCell();
    return () => {
      debouncedFetchCell.cancel();
    };
  }, [debouncedFetchCell]);

  useNotification(DatabaseNotification.DidUpdateCell, fetchCell, { id: `${rowId}:${fieldId}` });

  return cell;
};
