import { YDatabaseFields, YDatabaseFilters, YDatabaseSorts } from '@/application/collab.type';
import { withTestingFields } from '@/application/database-yjs/__tests__/withTestingField';
import { withTestingRowDataMap } from '@/application/database-yjs/__tests__/withTestingRows';
import * as Y from 'yjs';

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
  };
}
