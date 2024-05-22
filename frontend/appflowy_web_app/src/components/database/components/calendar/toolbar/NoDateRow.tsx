import { YjsDatabaseKey } from '@/application/collab.type';
import { useCellSelector, useDatabase } from '@/application/database-yjs';
import React, { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import Cell from 'src/components/database/components/cell/Cell';

function NoDateRow({ rowId }: { rowId: string }) {
  const database = useDatabase();
  const [primaryFieldId, setPrimaryFieldId] = React.useState<string | null>(null);
  const cell = useCellSelector({
    rowId,
    fieldId: primaryFieldId || '',
  });
  const { t } = useTranslation();

  useEffect(() => {
    const fields = database?.get(YjsDatabaseKey.fields);
    const primaryFieldId = Array.from(fields?.keys() || []).find((fieldId) => {
      return fields?.get(fieldId)?.get(YjsDatabaseKey.is_primary);
    });

    setPrimaryFieldId(primaryFieldId || null);
  }, [database]);

  if (!primaryFieldId || !cell?.data) {
    return <div className={'text-xs text-text-caption'}>{t('grid.row.titlePlaceholder')}</div>;
  }

  return (
    <div className={'w-full hover:text-fill-default'}>
      <Cell
        style={{
          cursor: 'pointer',
        }}
        readOnly
        cell={cell}
        rowId={rowId}
        fieldId={primaryFieldId}
      />
    </div>
  );
}

export default NoDateRow;
