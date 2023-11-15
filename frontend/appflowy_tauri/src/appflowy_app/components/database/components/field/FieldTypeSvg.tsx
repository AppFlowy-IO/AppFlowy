import { FC, memo } from 'react';
import { FieldType } from '@/services/backend';
import { ReactComponent as TextSvg } from '$app/assets/database/field-type-text.svg';
import { ReactComponent as NumberSvg } from '$app/assets/database/field-type-number.svg';
import { ReactComponent as DateSvg } from '$app/assets/database/field-type-date.svg';
import { ReactComponent as SingleSelectSvg } from '$app/assets/database/field-type-single-select.svg';
import { ReactComponent as MultiSelectSvg } from '$app/assets/database/field-type-multi-select.svg';
import { ReactComponent as ChecklistSvg } from '$app/assets/database/field-type-checklist.svg';
import { ReactComponent as CheckboxSvg } from '$app/assets/database/field-type-checkbox.svg';
import { ReactComponent as URLSvg } from '$app/assets/database/field-type-url.svg';
import { ReactComponent as LastEditedTimeSvg } from '$app/assets/database/field-type-last-edited-time.svg';

export const FieldTypeSvgMap: Record<FieldType, FC<React.SVGProps<SVGSVGElement>>> = {
  [FieldType.RichText]: TextSvg,
  [FieldType.Number]: NumberSvg,
  [FieldType.DateTime]: DateSvg,
  [FieldType.SingleSelect]: SingleSelectSvg,
  [FieldType.MultiSelect]: MultiSelectSvg,
  [FieldType.Checkbox]: CheckboxSvg,
  [FieldType.URL]: URLSvg,
  [FieldType.Checklist]: ChecklistSvg,
  [FieldType.LastEditedTime]: LastEditedTimeSvg,
  [FieldType.CreatedTime]: LastEditedTimeSvg,
};

export const FieldTypeSvg: FC<{ type: FieldType, className?: string }> = memo(({ type, ...props }) => {
  const Svg = FieldTypeSvgMap[type];

  return <Svg {...props} />;
});
