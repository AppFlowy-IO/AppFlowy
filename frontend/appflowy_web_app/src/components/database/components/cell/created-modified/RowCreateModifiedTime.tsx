import { YjsDatabaseKey } from '@/application/collab.type';
import { useRowMeta } from '@/application/database-yjs';
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
  const rowMeta = useRowMeta(rowId);
  const [value, setValue] = useState<string | null>(null);

  useEffect(() => {
    if (!rowMeta) return;
    const observeHandler = () => {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-expect-error
      setValue(rowMeta.get(attrName));
    };

    observeHandler();

    rowMeta.observe(observeHandler);
    return () => {
      rowMeta.unobserve(observeHandler);
    };
  }, [rowMeta, attrName]);

  const time = useMemo(() => {
    if (!value) return null;
    return getDateTimeStr(value, false);
  }, [value, getDateTimeStr]);

  if (!time) return null;
  return <div style={style}>{time}</div>;
}

export default RowCreateModifiedTime;
