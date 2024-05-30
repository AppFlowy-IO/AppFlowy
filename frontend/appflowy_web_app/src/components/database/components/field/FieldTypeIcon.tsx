import { FieldType } from '@/application/database-yjs/database.type';
import { FC, memo } from 'react';
import { ReactComponent as TextSvg } from '$icons/16x/text.svg';
import { ReactComponent as NumberSvg } from '$icons/16x/number.svg';
import { ReactComponent as DateSvg } from '$icons/16x/date.svg';
import { ReactComponent as SingleSelectSvg } from '$icons/16x/single_select.svg';
import { ReactComponent as MultiSelectSvg } from '$icons/16x/multiselect.svg';
import { ReactComponent as ChecklistSvg } from '$icons/16x/checklist.svg';
import { ReactComponent as CheckboxSvg } from '$icons/16x/checkbox.svg';
import { ReactComponent as URLSvg } from '$icons/16x/url.svg';
import { ReactComponent as LastEditedTimeSvg } from '$icons/16x/last_modified.svg';
import { ReactComponent as CreatedSvg } from '$icons/16x/created_at.svg';
import { ReactComponent as RelationSvg } from '$icons/16x/relation.svg';

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
  [FieldType.CreatedTime]: CreatedSvg,
  [FieldType.Relation]: RelationSvg,
};

export const FieldTypeIcon: FC<{ type: FieldType; className?: string }> = memo(({ type, ...props }) => {
  const Svg = FieldTypeSvgMap[type];

  return <Svg {...props} />;
});
