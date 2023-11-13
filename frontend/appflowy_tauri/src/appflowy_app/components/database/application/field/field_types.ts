import { FieldPB, FieldType, FieldVisibility } from '@/services/backend';
import { DateTimeTypeOption, NumberTypeOption, SelectTypeOption } from './type_option/type_option_types';

export interface Field {
  id: string;
  name: string;
  type: FieldType;
  typeOption?: unknown;
  visibility?: FieldVisibility;
  width?: number;
  isPrimary: boolean;
}

export interface NumberField extends Field {
  type: FieldType.Number;
  typeOption: NumberTypeOption;
}

export interface DateTimeField extends Field {
  type: FieldType.DateTime;
  typeOption: DateTimeTypeOption;
}

export interface SelectField extends Field {
  type: FieldType.SingleSelect | FieldType.MultiSelect;
  typeOption: SelectTypeOption;
}

export type UndeterminedField = NumberField | DateTimeField | SelectField | Field;

export const pbToField = (pb: FieldPB): Field => ({
  id: pb.id,
  name: pb.name,
  type: pb.field_type,
  isPrimary: pb.is_primary,
});
