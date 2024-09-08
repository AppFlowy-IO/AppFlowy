import { YjsDatabaseKey } from '@/application/collab.type';
import { FieldType, useCellSelector, useFieldSelector } from '@/application/database-yjs';
import { TextCell } from '@/application/database-yjs/cell.type';
import Cell from '@/components/database/components/cell/Cell';
import { PrimaryCell } from '@/components/database/components/cell/primary';
import React, { CSSProperties, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

export function CardField ({ rowId, fieldId }: { rowId: string; fieldId: string; index: number }) {
  const { t } = useTranslation();
  const { field } = useFieldSelector(fieldId);
  const cell = useCellSelector({
    rowId,
    fieldId,
  });

  const isPrimary = field?.get(YjsDatabaseKey.is_primary);
  const type = field?.get(YjsDatabaseKey.type);
  const style = useMemo(() => {
    const styleProperties: CSSProperties = {
      overflow: 'hidden',
      width: '100%',
      textAlign: 'left',
    };

    if (isPrimary || [FieldType.Relation, FieldType.SingleSelect, FieldType.MultiSelect].includes(Number(type))) {
      Object.assign(styleProperties, {
        breakWord: 'break-word',
        whiteSpace: 'normal',
        flexWrap: 'wrap',
      });
    } else {
      Object.assign(styleProperties, {
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap',
      });
    }

    if (isPrimary) {
      Object.assign(styleProperties, {
        fontSize: '1.25em',
        fontWeight: 500,
      });
    }

    return styleProperties;
  }, [isPrimary, type]);

  if (isPrimary) {
    if (!cell?.data) {
      return (
        <div className={'text-text-caption'} style={style}>
          {t('grid.row.titlePlaceholder')}
        </div>
      );
    } else {
      return <PrimaryCell showDocumentIcon readOnly cell={cell as TextCell} rowId={rowId} fieldId={fieldId}
                          style={style}
      />;
    }

  }

  if (Number(type) === FieldType.Checkbox) {
    return (
      <div className={'flex items-center gap-1'}>
        <span>
          <Cell readOnly cell={cell} rowId={rowId} fieldId={fieldId} />
        </span>
        <span>{field?.get(YjsDatabaseKey.name) || ''}</span>
      </div>
    );
  }

  return <Cell style={style} readOnly cell={cell} rowId={rowId} fieldId={fieldId} />;
}

export default CardField;
