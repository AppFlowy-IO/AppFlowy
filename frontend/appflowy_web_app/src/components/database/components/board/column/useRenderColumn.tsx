import { YjsDatabaseKey } from '@/application/collab.type';
import { FieldType, parseSelectOptionTypeOptions, useFieldSelector } from '@/application/database-yjs';
import { Tag } from '@/components/_shared/tag';
import { SelectOptionColorMap } from '@/components/database/components/cell/cell.const';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';

export function useRenderColumn(id: string, fieldId: string) {
  const { field } = useFieldSelector(fieldId);
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;
  const fieldName = field?.get(YjsDatabaseKey.name) || '';
  const { t } = useTranslation();
  const header = useMemo(() => {
    if (!field) return null;
    if (fieldType === FieldType.Checkbox)
      return (
        <div className={'flex items-center gap-2'}>
          {id === 'Yes' ? (
            <>
              <CheckboxCheckSvg className={'h-4 w-4'} />
              {t('button.yes')}
            </>
          ) : (
            <>
              {' '}
              <CheckboxUncheckSvg className={'h-4 w-4'} />
              {t('button.no')}
            </>
          )}
        </div>
      );
    if ([FieldType.SingleSelect, FieldType.MultiSelect].includes(fieldType)) {
      const option = parseSelectOptionTypeOptions(field)?.options.find((option) => option.id === id);

      return (
        <Tag
          label={option?.name || `No ${fieldName}`}
          color={option?.color ? SelectOptionColorMap[option?.color] : 'transparent'}
        />
      );
    }

    return null;
  }, [field, fieldType, id, fieldName, t]);

  return {
    header,
  };
}
