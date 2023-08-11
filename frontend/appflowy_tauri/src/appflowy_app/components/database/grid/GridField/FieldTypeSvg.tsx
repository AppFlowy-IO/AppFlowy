import { FC } from 'react';
import { FieldType } from '@/services/backend';
import { ReactComponent as TextSvg } from '$app/assets/database/field-type-text.svg';
import { ReactComponent as NumberSvg } from '$app/assets/database/field-type-number.svg';
import { ReactComponent as DateSvg } from '$app/assets/database/field-type-date.svg';
import { ReactComponent as SingleSelectSvg } from '$app/assets/database/field-type-single-select.svg';
import { ReactComponent as MultiSelectSvg } from '$app/assets/database/field-type-multi-select.svg';
import { ReactComponent as ChecklistSvg } from '$app/assets/database/field-type-checklist.svg';
import { ReactComponent as CheckboxSvg } from '$app/assets/database/field-type-checkbox.svg';

export const FieldTypeSvgMap: Record<number, FC<any>> = {
  [FieldType.RichText]: TextSvg,
  [FieldType.Number]: NumberSvg,
  [FieldType.DateTime]: DateSvg,
  [FieldType.SingleSelect]: SingleSelectSvg,
  [FieldType.MultiSelect]: MultiSelectSvg,
  [FieldType.Checklist]: ChecklistSvg,
  [FieldType.Checkbox]: CheckboxSvg,
};

export const FieldTypeSvg: FC<{ type: FieldType, className?: string }> = ({ type, ...props }) => {
  const Svg = FieldTypeSvgMap[type] ? FieldTypeSvgMap[type] : FieldTypeSvgMap[FieldType.RichText];

  return <Svg {...props} />;
}