import { useCellSelector, useDatabaseViewId, usePrimaryFieldId, useRowMetaSelector } from '@/application/database-yjs';
import { FolderContext } from '@/application/folder-yjs';
import Title from '@/components/database/components/header/Title';
import React, { useContext, useEffect } from 'react';

function DatabaseRowHeader({ rowId }: { rowId: string }) {
  const fieldId = usePrimaryFieldId() || '';
  const setCrumbs = useContext(FolderContext)?.setCrumbs;
  const viewId = useDatabaseViewId();

  const meta = useRowMetaSelector(rowId);
  const cell = useCellSelector({
    rowId,
    fieldId,
  });

  useEffect(() => {
    if (!viewId) return;
    setCrumbs?.((prev) => {
      const lastCrumb = prev[prev.length - 1];
      const crumb = {
        viewId,
        rowId,
        name: cell?.data as string,
        icon: meta?.icon || '',
      };

      if (lastCrumb?.rowId === rowId) return [...prev.slice(0, -1), crumb];
      return [...prev, crumb];
    });
  }, [cell, meta, rowId, setCrumbs, viewId]);

  return <Title icon={meta?.icon} name={cell?.data as string} />;
}

export default DatabaseRowHeader;
