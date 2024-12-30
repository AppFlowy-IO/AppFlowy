import {
  YDatabaseField,
  YDatabaseFieldTypeOption,
  YjsDatabaseKey,
  YMapFieldTypeOption,
} from '@/application/types';
import { FieldType } from '@/application/database-yjs';
import { SelectOptionColor } from '@/application/database-yjs/fields/select-option';
import * as Y from 'yjs';

export function withTestingFields() {
  const fields = new Y.Map();
  const textField = withRichTextTestingField();

  fields.set('text_field', textField);
  const numberField = withNumberTestingField();

  fields.set('number_field', numberField);

  const checkboxField = withCheckboxTestingField();

  fields.set('checkbox_field', checkboxField);

  const dateTimeField = withDateTimeTestingField();

  fields.set('date_field', dateTimeField);

  const singleSelectField = withSelectOptionTestingField();

  fields.set('single_select_field', singleSelectField);
  const multipleSelectField = withSelectOptionTestingField(true);

  fields.set('multi_select_field', multipleSelectField);

  const urlField = withURLTestingField();

  fields.set('url_field', urlField);

  const checklistField = withChecklistTestingField();

  fields.set('checklist_field', checklistField);

  const createdAtField = withCreatedAtTestingField();

  fields.set('created_at_field', createdAtField);

  const lastModifiedField = withLastModifiedTestingField();

  fields.set('last_modified_field', lastModifiedField);

  return fields;
}

export function withRichTextTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'Rich Text Field');
  field.set(YjsDatabaseKey.id, 'text_field');
  field.set(YjsDatabaseKey.type, String(FieldType.RichText));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());

  return field;
}

export function withNumberTestingField() {
  const field = new Y.Map() as YDatabaseField;
  
  field.set(YjsDatabaseKey.name, 'Number Field');
  field.set(YjsDatabaseKey.id, 'number_field');
  field.set(YjsDatabaseKey.type, String(FieldType.Number));
  const typeOption = new Y.Map() as YDatabaseFieldTypeOption;

  const numberTypeOption = new Y.Map() as YMapFieldTypeOption;

  typeOption.set(String(FieldType.Number), numberTypeOption);
  numberTypeOption.set(YjsDatabaseKey.format, '0');
  field.set(YjsDatabaseKey.type_option, typeOption);

  return field;
}

export function withRelationTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const typeOption = new Y.Map() as YDatabaseFieldTypeOption;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'Relation Field');
  field.set(YjsDatabaseKey.id, 'relation_field');
  field.set(YjsDatabaseKey.type, String(FieldType.Relation));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());
  field.set(YjsDatabaseKey.type_option, typeOption);

  return field;
}

export function withCheckboxTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'Checkbox Field');
  field.set(YjsDatabaseKey.id, 'checkbox_field');
  field.set(YjsDatabaseKey.type, String(FieldType.Checkbox));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());

  return field;
}

export function withDateTimeTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const typeOption = new Y.Map() as YDatabaseFieldTypeOption;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'DateTime Field');
  field.set(YjsDatabaseKey.id, 'date_field');
  field.set(YjsDatabaseKey.type, String(FieldType.DateTime));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());
  field.set(YjsDatabaseKey.type_option, typeOption);

  const dateTypeOption = new Y.Map() as YMapFieldTypeOption;

  typeOption.set(String(FieldType.DateTime), dateTypeOption);

  dateTypeOption.set(YjsDatabaseKey.time_format, '0');
  dateTypeOption.set(YjsDatabaseKey.date_format, '0');
  return field;
}

export function withURLTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'URL Field');
  field.set(YjsDatabaseKey.id, 'url_field');
  field.set(YjsDatabaseKey.type, String(FieldType.URL));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());

  return field;
}

export function withSelectOptionTestingField(isMultiple = false) {
  const field = new Y.Map() as YDatabaseField;
  const typeOption = new Y.Map() as YDatabaseFieldTypeOption;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'Single Select Field');
  field.set(YjsDatabaseKey.id, isMultiple ? 'multi_select_field' : 'single_select_field');
  field.set(YjsDatabaseKey.type, String(FieldType.SingleSelect));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());
  field.set(YjsDatabaseKey.type_option, typeOption);

  const selectTypeOption = new Y.Map() as YMapFieldTypeOption;

  typeOption.set(String(FieldType.SingleSelect), selectTypeOption);

  selectTypeOption.set(
    YjsDatabaseKey.content,
    JSON.stringify({
      disable_color: false,
      options: [
        { id: '1', name: 'Option 1', color: SelectOptionColor.Purple },
        { id: '2', name: 'Option 2', color: SelectOptionColor.Pink },
        { id: '3', name: 'Option 3', color: SelectOptionColor.LightPink },
      ],
    })
  );
  return field;
}

export function withChecklistTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'Checklist Field');
  field.set(YjsDatabaseKey.id, 'checklist_field');
  field.set(YjsDatabaseKey.type, String(FieldType.Checklist));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());

  return field;
}

export function withCreatedAtTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'Created At Field');
  field.set(YjsDatabaseKey.id, 'created_at_field');
  field.set(YjsDatabaseKey.type, String(FieldType.CreatedTime));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());

  return field;
}

export function withLastModifiedTestingField() {
  const field = new Y.Map() as YDatabaseField;
  const now = Date.now().toString();

  field.set(YjsDatabaseKey.name, 'Last Modified Field');
  field.set(YjsDatabaseKey.id, 'last_modified_field');
  field.set(YjsDatabaseKey.type, String(FieldType.LastEditedTime));
  field.set(YjsDatabaseKey.last_modified, now.valueOf());

  return field;
}
