import { YDatabaseSort, YjsDatabaseKey } from '@/application/collab.type';
import * as Y from 'yjs';
import * as sortsJson from './fixtures/sorts.json';

export function withRichTextSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_text_field : sortsJson.sort_desc_text_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}

export function withUrlSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_url_field : sortsJson.sort_desc_url_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}

export function withNumberSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_number_field : sortsJson.sort_desc_number_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}

export function withCheckboxSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_checkbox_field : sortsJson.sort_desc_checkbox_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}

export function withDateTimeSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_date_field : sortsJson.sort_desc_date_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}

export function withSingleSelectOptionSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_single_select_field : sortsJson.sort_desc_single_select_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}

export function withMultiSelectOptionSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_multi_select_field : sortsJson.sort_desc_multi_select_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}

export function withChecklistSort(isAscending: boolean = true) {
  const sort = new Y.Map() as YDatabaseSort;
  const sortJSON = isAscending ? sortsJson.sort_asc_checklist_field : sortsJson.sort_desc_checklist_field;

  sort.set(YjsDatabaseKey.id, sortJSON.id);
  sort.set(YjsDatabaseKey.field_id, sortJSON.field_id);
  sort.set(YjsDatabaseKey.condition, sortJSON.condition === 'asc' ? '0' : '1');

  return sort;
}
