import { FieldType } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import { useCallback } from 'react';

export const FieldTypeText = ({ type }: { type: FieldType }) => {
  const { t } = useTranslation();

  const getText = useCallback(
    (type: FieldType) => {
      switch (type) {
        case FieldType.RichText:
          return t('grid.field.textFieldName');
        case FieldType.Number:
          return t('grid.field.numberFieldName');
        case FieldType.DateTime:
          return t('grid.field.dateFieldName');
        case FieldType.SingleSelect:
          return t('grid.field.singleSelectFieldName');
        case FieldType.MultiSelect:
          return t('grid.field.multiSelectFieldName');
        case FieldType.Checkbox:
          return t('grid.field.checkboxFieldName');
        case FieldType.URL:
          return t('grid.field.urlFieldName');
        case FieldType.Checklist:
          return t('grid.field.checklistFieldName');
        case FieldType.LastEditedTime:
          return t('grid.field.updatedAtFieldName');
        case FieldType.CreatedTime:
          return t('grid.field.createdAtFieldName');
        default:
          return '';
      }
    },
    [t]
  );

  return <>{getText(type)}</>;
};
