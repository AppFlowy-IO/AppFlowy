import { FC } from 'react';
import { FieldType } from '@/services/backend';

import { Cell as CellType, Field } from '../../application';
import { useCell } from './Cell.hooks';
import { TextCell } from './TextCell';
import { SelectCell } from './SelectCell';
import { CheckboxCell } from './CheckboxCell';

export interface CellProps {
  rowId: string;
  field: Field;
  documentId?: string;
  icon?: string;
  placeholder?: string;
}

const getCellComponent = (fieldType: FieldType) => {
  switch (fieldType) {
    case FieldType.RichText:
      return TextCell as FC<{ field: Field; cell?: CellType }>;
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return SelectCell as FC<{ field: Field; cell?: CellType }>;
    case FieldType.Checkbox:
      return CheckboxCell as FC<{ field: Field; cell?: CellType }>;
    default:
      return null;
  }
};

export const Cell: FC<CellProps> = ({ rowId, field, ...props }) => {
  const cell = useCell(rowId, field.id, field.type);

  const Component = getCellComponent(field.type);

  if (!Component) {
    return null;
  }

  return <Component {...props} field={field} cell={cell} />;
};
