import { useCallback, useEffect, useState } from 'react';
import { Result } from 'ts-results';
import { DatabaseNotification, FieldType, FlowyError } from '@/services/backend';
import { Database, cellPbToCell } from '$app/interfaces/database';
import * as service from '$app/components/database/database_bd_svc';
import { useNotification } from '$app/hooks';
import { useViewId } from '../../database.hooks';

export const useCell = (rowId: string, fieldId: string, fieldType: FieldType) => {
  const viewId = useViewId();
  const [cell, setCell] = useState<Database.Cell | null>(null);

  const fetchCell = useCallback(() => {
    void service.getCell(viewId, rowId, fieldId).then(data => {
      setCell(cellPbToCell(data, fieldType));
    });
  }, [viewId, rowId, fieldId, fieldType]);

  useEffect(() => {
    void fetchCell();
  }, [fetchCell]);

  const didUpdateCell = useCallback((result: Result<void, FlowyError>) => {
    if (result.err) {
      return;
    }

    void fetchCell();
  }, [fetchCell]);

  useNotification(DatabaseNotification.DidUpdateCell, didUpdateCell, { id: `${rowId}:${fieldId}` });

  return cell;
};
