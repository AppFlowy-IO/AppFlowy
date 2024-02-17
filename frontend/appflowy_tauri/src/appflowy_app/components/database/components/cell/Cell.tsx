import React, { FC, HTMLAttributes } from 'react';
import { FieldType } from '@/services/backend';

import { Cell as CellType, Field } from '$app/application/database';
import { useCell } from './Cell.hooks';
import { TextCell } from './TextCell';
import { SelectCell } from './SelectCell';
import { CheckboxCell } from './CheckboxCell';
import NumberCell from '$app/components/database/components/cell/NumberCell';
import URLCell from '$app/components/database/components/cell/URLCell';
import ChecklistCell from '$app/components/database/components/cell/ChecklistCell';
import DateTimeCell from '$app/components/database/components/cell/DateTimeCell';
import TimestampCell from '$app/components/database/components/cell/TimestampCell';

export interface CellProps extends HTMLAttributes<HTMLDivElement> {
  rowId: string;
  field: Field;
  icon?: string;
  placeholder?: string;
}

export interface CellComponentProps extends CellProps {
  cell: CellType;
}

const getCellComponent = (fieldType: FieldType) => {
  switch (fieldType) {
    case FieldType.RichText:
      return TextCell as FC<CellComponentProps>;
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return SelectCell as FC<CellComponentProps>;
    case FieldType.Checkbox:
      return CheckboxCell as FC<CellComponentProps>;
    case FieldType.Checklist:
      return ChecklistCell as FC<CellComponentProps>;
    case FieldType.Number:
      return NumberCell as FC<CellComponentProps>;
    case FieldType.URL:
      return URLCell as FC<CellComponentProps>;
    case FieldType.DateTime:
      return DateTimeCell as FC<CellComponentProps>;
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return TimestampCell as FC<CellComponentProps>;
    default:
      return null;
  }
};

export const Cell: FC<CellProps> = ({ rowId, field, ...props }) => {
  const cell = useCell(rowId, field);

  const Component = getCellComponent(field.type);

  if (!cell) {
    return <div className={`h-[36px] w-[${field.width}px]`} />;
  }

  if (!Component) {
    return null;
  }

  return <Component {...props} rowId={rowId} field={field} cell={cell} />;
};
