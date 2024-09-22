import { FieldType } from '@/application/database-yjs/database.type';
import { FC, memo } from 'react';
import { ReactComponent as TextSvg } from '@/assets/text.svg';
import { ReactComponent as NumberSvg } from '@/assets/number.svg';
import { ReactComponent as DateSvg } from '@/assets/date.svg';
import { ReactComponent as SingleSelectSvg } from '@/assets/single_select.svg';
import { ReactComponent as MultiSelectSvg } from '@/assets/multiselect.svg';
import { ReactComponent as ChecklistSvg } from '@/assets/checklist.svg';
import { ReactComponent as CheckboxSvg } from '@/assets/checkbox.svg';
import { ReactComponent as URLSvg } from '@/assets/url.svg';
import { ReactComponent as LastEditedTimeSvg } from '@/assets/last_modified.svg';
import { ReactComponent as CreatedSvg } from '@/assets/created_at.svg';
import { ReactComponent as RelationSvg } from '@/assets/relation.svg';
import { ReactComponent as AISummariesSvg } from '@/assets/ai_summary.svg';
import { ReactComponent as AITranslationsSvg } from '@/assets/ai_translate.svg';
import { ReactComponent as FileMediaSvg } from '@/assets/media.svg';

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
  [FieldType.AISummaries]: AISummariesSvg,
  [FieldType.AITranslations]: AITranslationsSvg,
  [FieldType.FileMedia]: FileMediaSvg,
};

export const FieldTypeIcon: FC<{ type: FieldType; className?: string }> = memo(({ type, ...props }) => {
  const Svg = FieldTypeSvgMap[type];

  if (!Svg) return null;
  return <Svg {...props} />;
});
