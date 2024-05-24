import { YjsDatabaseKey } from '@/application/collab.type';
import { useRowData } from '@/application/database-yjs';
import { useDateTypeCellDispatcher } from '@/components/database/components/cell/Cell.hooks';
import React, { useEffect, useMemo, useState } from 'react';

export function RowCreateModifiedTime({
  rowId,
  fieldId,
  attrName,
  style,
}: {
  rowId: string;
  fieldId: string;
  style?: React.CSSProperties;
  attrName: YjsDatabaseKey.last_modified | YjsDatabaseKey.created_at;
}) {
  const { getDateTimeStr } = useDateTypeCellDispatcher(fieldId);
  const rowData = useRowData(rowId);
  const [value, setValue] = useState<string | null>(null);

  useEffect(() => {
    if (!rowData) return;
    const observeHandler = () => {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-expect-error
      setValue(rowData.get(attrName));
    };

    observeHandler();

    rowData.observe(observeHandler);
    return () => {
      rowData.unobserve(observeHandler);
    };
  }, [rowData, attrName]);

  const time = useMemo(() => {
    if (!value) return null;
    return getDateTimeStr(value, false);
  }, [value, getDateTimeStr]);

  if (!time) return null;
  return (
    <div style={style} className={'flex w-full items-center'}>
      {time}
    </div>
  );
}

export default RowCreateModifiedTime;
