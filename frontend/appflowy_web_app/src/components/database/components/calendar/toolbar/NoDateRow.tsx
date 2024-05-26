import { useCellSelector, useNavigateToRow, usePrimaryFieldId } from '@/application/database-yjs';
import { Cell } from '@/components/database/components/cell';
import React from 'react';
import { useTranslation } from 'react-i18next';

function NoDateRow({ rowId }: { rowId: string }) {
  const navigateToRow = useNavigateToRow();
  const primaryFieldId = usePrimaryFieldId();
  const cell = useCellSelector({
    rowId,
    fieldId: primaryFieldId || '',
  });
  const { t } = useTranslation();

  if (!primaryFieldId || !cell?.data) {
    return <div className={'text-xs text-text-caption'}>{t('grid.row.titlePlaceholder')}</div>;
  }

  return (
    <div
      onClick={() => {
        navigateToRow?.(rowId);
      }}
      className={'w-full hover:text-fill-default'}
    >
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
