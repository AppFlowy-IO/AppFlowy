import {
  YDatabase,
  YDatabaseFields,
  YDatabaseFilters,
  YDatabaseGroup,
  YDatabaseGroupColumn,
  YDatabaseGroupColumns,
  YDatabaseLayoutSettings,
  YDatabaseSorts,
  YDatabaseView,
  YDatabaseViews,
  YDoc,
  YjsDatabaseKey,
  YjsEditorKey,
} from '@/application/types';
import { withTestingFields } from '@/application/database-yjs/__tests__/withTestingField';
import {
  withTestingRowData,
  withTestingRowDataMap,
  withTestingRows,
} from '@/application/database-yjs/__tests__/withTestingRows';
import * as Y from 'yjs';
import { withMultiSelectOptionFilter } from '@/application/database-yjs/__tests__/withTestingFilters';
import { withRichTextSort } from '@/application/database-yjs/__tests__/withTestingSorts';
import { metaIdFromRowId, RowMetaKey } from '@/application/database-yjs';

export function withTestingData() {
  const doc = new Y.Doc();
  const sharedRoot = doc.getMap();
  const fields = withTestingFields() as YDatabaseFields;

  sharedRoot.set('fields', fields);

  const rowMap = withTestingRowDataMap();

  sharedRoot.set('rows', rowMap);

  const sorts = new Y.Array() as YDatabaseSorts;

  sharedRoot.set('sorts', sorts);

  const filters = new Y.Array() as YDatabaseFilters;

  sharedRoot.set('filters', filters);

  return {
    fields,
    rowMap,
    sorts,
    filters,
    doc,
  };
}

export function withTestingDatabase(viewId: string) {
  const doc = new Y.Doc();
  const sharedRoot = doc.getMap(YjsEditorKey.data_section);
  const database = new Y.Map() as YDatabase;

  sharedRoot.set(YjsEditorKey.database, database);

  const fields = withTestingFields() as YDatabaseFields;

  database.set(YjsDatabaseKey.fields, fields);
  database.set(YjsDatabaseKey.id, viewId);

  const metas = new Y.Map();

  database.set(YjsDatabaseKey.metas, metas);
  metas.set(YjsDatabaseKey.iid, viewId);

  const views = new Y.Map() as YDatabaseViews;

  database.set(YjsDatabaseKey.views, views);

  const view = new Y.Map() as YDatabaseView;

  views.set('1', view);
  view.set(YjsDatabaseKey.id, viewId);
  view.set(YjsDatabaseKey.layout, 0);
  view.set(YjsDatabaseKey.name, 'View 1');
  view.set(YjsDatabaseKey.database_id, viewId);

  const layoutSetting = new Y.Map() as YDatabaseLayoutSettings;

  const calendarSetting = new Y.Map();

  calendarSetting.set(YjsDatabaseKey.field_id, 'date_field');
  layoutSetting.set('2', calendarSetting);

  view.set(YjsDatabaseKey.layout_settings, layoutSetting);

  const filters = new Y.Array() as YDatabaseFilters;
  const filter = withMultiSelectOptionFilter();

  filters.push([filter]);

  const sorts = new Y.Array() as YDatabaseSorts;
  const sort = withRichTextSort();

  sorts.push([sort]);

  const groups = new Y.Array();
  const group = new Y.Map() as YDatabaseGroup;

  groups.push([group]);
  group.set(YjsDatabaseKey.id, 'g:single_select_field');
  group.set(YjsDatabaseKey.field_id, 'single_select_field');
  group.set(YjsDatabaseKey.type, '3');
  group.set(YjsDatabaseKey.content, '');

  const groupColumns = new Y.Array() as YDatabaseGroupColumns;

  group.set(YjsDatabaseKey.groups, groupColumns);

  const column1 = new Y.Map() as YDatabaseGroupColumn;
  const column2 = new Y.Map() as YDatabaseGroupColumn;

  column1.set(YjsDatabaseKey.id, '1');
  column1.set(YjsDatabaseKey.visible, true);
  column2.set(YjsDatabaseKey.id, 'single_select_field');
  column2.set(YjsDatabaseKey.visible, true);

  groupColumns.push([column1]);
  groupColumns.push([column2]);

  view.set(YjsDatabaseKey.filters, filters);
  view.set(YjsDatabaseKey.sorts, sorts);
  view.set(YjsDatabaseKey.groups, groups);

  const fieldSettings = new Y.Map();
  const fieldOrder = new Y.Array();
  const rowOrders = new Y.Array();

  fields.forEach((field) => {
    const setting = new Y.Map();

    const fieldId = field.get(YjsDatabaseKey.id);

    if (fieldId === 'text_field') {
      field.set(YjsDatabaseKey.is_primary, true);
    }

    fieldOrder.push([fieldId]);
    fieldSettings.set(fieldId, setting);
    setting.set(YjsDatabaseKey.visibility, 0);
  });
  const rows = withTestingRows();

  rows.forEach(({ id, height }) => {
    const row = new Y.Map();

    row.set(YjsDatabaseKey.id, id);
    row.set(YjsDatabaseKey.height, height);
    rowOrders.push([row]);
  });

  view.set(YjsDatabaseKey.field_settings, fieldSettings);
  view.set(YjsDatabaseKey.field_orders, fieldOrder);
  view.set(YjsDatabaseKey.row_orders, rowOrders);

  const rowMapDoc = new Y.Doc();

  const rowMapFolder = rowMapDoc.getMap();

  rows.forEach((row, index) => {
    const rowDoc = new Y.Doc();
    const rowData = withTestingRowData(row.id, index);
    const rowMeta = new Y.Map();
    const parser = metaIdFromRowId('281e76fb-712e-59e2-8370-678bf0788355');

    rowMeta.set(parser(RowMetaKey.IconId), '😊');
    rowDoc.getMap(YjsEditorKey.data_section).set(YjsEditorKey.meta, rowMeta);
    rowDoc.getMap(YjsEditorKey.data_section).set(YjsEditorKey.database_row, rowData);
    rowMapFolder.set(row.id, rowDoc);
  });

  return {
    rowDocMap: rowMapFolder as Y.Map<YDoc>,
    doc: doc as YDoc,
  };
}
