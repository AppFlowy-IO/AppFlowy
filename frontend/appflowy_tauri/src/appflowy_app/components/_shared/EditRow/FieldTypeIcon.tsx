import { FieldType } from '@/services/backend';
import { TextTypeSvg } from '$app/components/_shared/svg/TextTypeSvg';
import { NumberTypeSvg } from '$app/components/_shared/svg/NumberTypeSvg';
import { DateTypeSvg } from '$app/components/_shared/svg/DateTypeSvg';
import { SingleSelectTypeSvg } from '$app/components/_shared/svg/SingleSelectTypeSvg';
import { MultiSelectTypeSvg } from '$app/components/_shared/svg/MultiSelectTypeSvg';
import { ChecklistTypeSvg } from '$app/components/_shared/svg/ChecklistTypeSvg';
import { UrlTypeSvg } from '$app/components/_shared/svg/UrlTypeSvg';
import { CheckboxSvg } from '$app/components/_shared/svg/CheckboxSvg';

export const FieldTypeIcon = ({ fieldType }: { fieldType: FieldType }) => {
  return (
    <>
      {fieldType === FieldType.RichText && <TextTypeSvg></TextTypeSvg>}
      {fieldType === FieldType.Number && <NumberTypeSvg></NumberTypeSvg>}
      {fieldType === FieldType.DateTime && <DateTypeSvg></DateTypeSvg>}
      {fieldType === FieldType.SingleSelect && <SingleSelectTypeSvg></SingleSelectTypeSvg>}
      {fieldType === FieldType.MultiSelect && <MultiSelectTypeSvg></MultiSelectTypeSvg>}
      {fieldType === FieldType.Checklist && <ChecklistTypeSvg></ChecklistTypeSvg>}
      {fieldType === FieldType.URL && <UrlTypeSvg></UrlTypeSvg>}
      {fieldType === FieldType.Checkbox && <CheckboxSvg></CheckboxSvg>}
    </>
  );
};
