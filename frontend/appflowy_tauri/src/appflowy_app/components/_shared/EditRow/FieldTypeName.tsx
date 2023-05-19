import { FieldType } from '@/services/backend';
import { useTranslation } from 'react-i18next';

export const FieldTypeName = ({ fieldType }: { fieldType: FieldType }) => {
  const { t } = useTranslation();
  return (
    <>
      {fieldType === FieldType.RichText && t('grid.field.textFieldName')}
      {fieldType === FieldType.Number && t('grid.field.numberFieldName')}
      {fieldType === FieldType.DateTime && t('grid.field.dateFieldName')}
      {fieldType === FieldType.SingleSelect && t('grid.field.singleSelectFieldName')}
      {fieldType === FieldType.MultiSelect && t('grid.field.multiSelectFieldName')}
      {fieldType === FieldType.Checklist && t('grid.field.checklistFieldName')}
      {fieldType === FieldType.URL && t('grid.field.urlFieldName')}
      {fieldType === FieldType.Checkbox && t('grid.field.checkboxFieldName')}
    </>
  );
};
