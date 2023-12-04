import { FieldType } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import { useMemo } from 'react';

export const PropertyTypeText = ({ type }: { type: FieldType }) => {
  const { t } = useTranslation();

  const text = useMemo(() => {
    const map = {
      [FieldType.RichText]: t('grid.field.textFieldName'),
      [FieldType.Number]: t('grid.field.numberFieldName'),
      [FieldType.DateTime]: t('grid.field.dateFieldName'),
      [FieldType.SingleSelect]: t('grid.field.singleSelectFieldName'),
      [FieldType.MultiSelect]: t('grid.field.multiSelectFieldName'),
      [FieldType.Checkbox]: t('grid.field.checkboxFieldName'),
      [FieldType.URL]: t('grid.field.urlFieldName'),
      [FieldType.Checklist]: t('grid.field.checklistFieldName'),
      [FieldType.LastEditedTime]: t('grid.field.updatedAtFieldName'),
      [FieldType.CreatedTime]: t('grid.field.createdAtFieldName'),
    };

    return map[type] || 'unknown';
  }, [t, type]);

  return <div>{text}</div>;
};
