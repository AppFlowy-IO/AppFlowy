import { FieldPB, FieldType, FieldVisibility } from '@/services/backend';

export interface Field {
  id: string;
  name: string;
  type: FieldType;
  visibility?: FieldVisibility;
  width?: number;
  isPrimary: boolean;
}

export interface NumberField extends Field {
  type: FieldType.Number;
}

export interface DateTimeField extends Field {
  type: FieldType.DateTime;
}

export interface LastEditedTimeField extends Field {
  type: FieldType.LastEditedTime;
}

export interface CreatedTimeField extends Field {
  type: FieldType.CreatedTime;
}

export type UndeterminedDateField = DateTimeField | CreatedTimeField | LastEditedTimeField;

export interface SelectField extends Field {
  type: FieldType.SingleSelect | FieldType.MultiSelect;
}

export interface ChecklistField extends Field {
  type: FieldType.Checklist;
}

export interface DateTimeField extends Field {
  type: FieldType.DateTime;
}

export type UndeterminedField = NumberField | DateTimeField | SelectField | Field;

export const pbToField = (pb: FieldPB): Field => {
  return {
    id: pb.id,
    name: pb.name,
    type: pb.field_type,
    isPrimary: pb.is_primary,
  };
};
