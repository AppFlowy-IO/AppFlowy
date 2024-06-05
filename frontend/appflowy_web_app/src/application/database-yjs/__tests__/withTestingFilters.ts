import { YDatabaseFilter, YjsDatabaseKey } from '@/application/collab.type';
import * as Y from 'yjs';
import * as filtersJson from './fixtures/filters.json';

export function withRichTextFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_text_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_text_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_text_field.condition);
  filter.set(YjsDatabaseKey.content, filtersJson.filter_text_field.content);
  return filter;
}

export function withUrlFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_url_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_url_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_url_field.condition);
  filter.set(YjsDatabaseKey.content, filtersJson.filter_url_field.content);
  return filter;
}

export function withNumberFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_number_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_number_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_number_field.condition);
  filter.set(YjsDatabaseKey.content, filtersJson.filter_number_field.content);
  return filter;
}

export function withCheckboxFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_checkbox_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_checkbox_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_checkbox_field.condition);
  filter.set(YjsDatabaseKey.content, '');
  return filter;
}

export function withChecklistFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_checklist_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_checklist_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_checklist_field.condition);
  filter.set(YjsDatabaseKey.content, '');
  return filter;
}

export function withSingleSelectOptionFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_single_select_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_single_select_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_single_select_field.condition);
  filter.set(YjsDatabaseKey.content, filtersJson.filter_single_select_field.content);
  return filter;
}

export function withMultiSelectOptionFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_multi_select_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_multi_select_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_multi_select_field.condition);
  filter.set(YjsDatabaseKey.content, filtersJson.filter_multi_select_field.content);
  return filter;
}

export function withDateTimeFilter() {
  const filter = new Y.Map() as YDatabaseFilter;

  filter.set(YjsDatabaseKey.id, 'filter_date_field');
  filter.set(YjsDatabaseKey.field_id, filtersJson.filter_date_field.field_id);
  filter.set(YjsDatabaseKey.condition, filtersJson.filter_date_field.condition);
  filter.set(YjsDatabaseKey.content, filtersJson.filter_date_field.content);
  return filter;
}
