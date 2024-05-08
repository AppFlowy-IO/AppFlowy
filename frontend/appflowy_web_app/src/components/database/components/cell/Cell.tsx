import { FieldId, YjsDatabaseKey } from '@/application/collab.type';
import { FieldType } from '@/application/database-yjs/database.type';
import { useFieldSelector } from '@/application/database-yjs/selector';
import RowCreateModifiedTime from '@/components/database/components/cell/RowCreateModifiedTime';
import React, { FC, useMemo } from 'react';
import RichTextCell from '@/components/database/components/cell/TextCell';
import UrlCell from '@/components/database/components/cell/UrlCell';
import NumberCell from '@/components/database/components/cell/NumberCell';
import CheckboxCell from '@/components/database/components/cell/CheckboxCell';
import SelectCell from '@/components/database/components/cell/SelectionCell';
import DateTimeCell from '@/components/database/components/cell/DateTimeCell';
import ChecklistCell from '@/components/database/components/cell/ChecklistCell';
import { Cell as CellValue } from '@/components/database/components/cell/cell.type';
import RelationCell from '@/components/database/components/cell/RelationCell';

export interface CellProps {
  rowId: string;
  fieldId: FieldId;
  cell?: CellValue;
}

export function Cell({ cell, rowId, fieldId }: CellProps) {
  const { field } = useFieldSelector(fieldId);
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;
  const Component = useMemo(() => {
    switch (fieldType) {
      case FieldType.RichText:
        return RichTextCell;
      case FieldType.URL:
        return UrlCell;
      case FieldType.Number:
        return NumberCell;
      case FieldType.Checkbox:
        return CheckboxCell;
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return SelectCell;
      case FieldType.DateTime:
        return DateTimeCell;
      case FieldType.Checklist:
        return ChecklistCell;
      case FieldType.Relation:
        return RelationCell;
      default:
        return RichTextCell;
    }
  }, [fieldType]) as FC<{ cell?: CellValue; rowId: string; fieldId: FieldId }>;

  if (fieldType === FieldType.CreatedTime || fieldType === FieldType.LastEditedTime) {
    const attrName = fieldType === FieldType.CreatedTime ? YjsDatabaseKey.created_at : YjsDatabaseKey.last_modified;

    return <RowCreateModifiedTime rowId={rowId} fieldId={fieldId} attrName={attrName} />;
  }

  if (cell?.fieldType !== fieldType) {
    return null;
  }

  return <Component cell={cell} rowId={rowId} fieldId={fieldId} />;
}

export default Cell;
