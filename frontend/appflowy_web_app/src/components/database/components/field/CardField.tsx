import { YjsDatabaseKey } from '@/application/collab.type';
import { useCellSelector, useFieldSelector } from '@/application/database-yjs';
import Cell from '@/components/database/components/cell/Cell';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function CardField({ rowId, fieldId, index }: { rowId: string; fieldId: string; index: number }) {
  const { t } = useTranslation();
  const { field } = useFieldSelector(fieldId);
  const cell = useCellSelector({
    rowId,
    fieldId,
  });

  const isPrimary = field?.get(YjsDatabaseKey.is_primary);
  const style = useMemo(() => {
    const styleProperties = {};

    if (isPrimary) {
      Object.assign(styleProperties, {
        fontSize: '1.25em',
        fontWeight: 500,
      });
    }

    if (index !== 0) {
      Object.assign(styleProperties, {
        marginTop: '8px',
      });
    }

    return styleProperties;
  }, [index, isPrimary]);

  if (isPrimary && !cell?.data) {
    return (
      <div className={'text-text-caption'} style={style}>
        {t('grid.row.titlePlaceholder')}
      </div>
    );
  }

  return <Cell style={style} readOnly cell={cell} rowId={rowId} fieldId={fieldId} />;
}

export default CardField;
