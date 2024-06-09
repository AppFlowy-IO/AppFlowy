import { FieldType, Row } from '@/application/database-yjs';
import { withTestingData } from '@/application/database-yjs/__tests__/withTestingData';
import { withTestingRows } from '@/application/database-yjs/__tests__/withTestingRows';
import { expect } from '@jest/globals';
import { groupByField } from '../group';
import * as Y from 'yjs';
import {
  YDatabaseField,
  YDatabaseFieldTypeOption,
  YjsDatabaseKey,
  YjsEditorKey,
  YMapFieldTypeOption,
} from '@/application/collab.type';
import { YjsEditor } from '@/application/slate-yjs';

describe('Database group', () => {
  let rows: Row[];

  beforeEach(() => {
    rows = withTestingRows();
  });

  it('should return undefined if field is not select option', () => {
    const { fields, rowMap } = withTestingData();
    expect(groupByField(rows, rowMap, fields.get('text_field'))).toBeUndefined();
    expect(groupByField(rows, rowMap, fields.get('number_field'))).toBeUndefined();
    expect(groupByField(rows, rowMap, fields.get('checkbox_field'))).toBeUndefined();
    expect(groupByField(rows, rowMap, fields.get('checklist_field'))).toBeUndefined();
  });

  it('should group by select option field', () => {
    const { fields, rowMap } = withTestingData();
    const field = fields.get('single_select_field');
    const result = groupByField(rows, rowMap, field);
    const expectRes = new Map([
      [
        '1',
        [
          { id: '1', height: 37 },
          { id: '4', height: 37 },
          { id: '7', height: 37 },
          { id: '10', height: 37 },
        ],
      ],
      [
        '2',
        [
          { id: '2', height: 37 },
          { id: '5', height: 37 },
          { id: '8', height: 37 },
        ],
      ],
      [
        '3',
        [
          { id: '3', height: 37 },
          { id: '6', height: 37 },
          { id: '9', height: 37 },
        ],
      ],
    ]);
    expect(result).toEqual(expectRes);
  });

  it('should group by multi select option field', () => {
    const { fields, rowMap } = withTestingData();
    const field = fields.get('multi_select_field');
    const result = groupByField(rows, rowMap, field);
    const expectRes = new Map([
      [
        '1',
        [
          { id: '1', height: 37 },
          { id: '3', height: 37 },
          { id: '5', height: 37 },
          { id: '6', height: 37 },
          { id: '7', height: 37 },
          { id: '9', height: 37 },
        ],
      ],
      [
        '2',
        [
          { id: '1', height: 37 },
          { id: '2', height: 37 },
          { id: '4', height: 37 },
          { id: '5', height: 37 },
          { id: '7', height: 37 },
          { id: '8', height: 37 },
          { id: '10', height: 37 },
        ],
      ],
      [
        '3',
        [
          { id: '2', height: 37 },
          { id: '3', height: 37 },
          { id: '5', height: 37 },
          { id: '6', height: 37 },
          { id: '8', height: 37 },
          { id: '9', height: 37 },
        ],
      ],
    ]);
    expect(result).toEqual(expectRes);
  });

  it('should not group if no options', () => {
    const { fields, rowMap } = withTestingData();
    const field = new Y.Map() as YDatabaseField;
    const typeOption = new Y.Map() as YDatabaseFieldTypeOption;
    const now = Date.now().toString();

    field.set(YjsDatabaseKey.name, 'Single Select Field');
    field.set(YjsDatabaseKey.id, 'another_single_select_field');
    field.set(YjsDatabaseKey.type, String(FieldType.SingleSelect));
    field.set(YjsDatabaseKey.last_modified, now.valueOf());
    field.set(YjsDatabaseKey.type_option, typeOption);
    fields.set('another_single_select_field', field);
    expect(groupByField(rows, rowMap, field)).toBeUndefined();

    const selectTypeOption = new Y.Map() as YMapFieldTypeOption;

    typeOption.set(String(FieldType.SingleSelect), selectTypeOption);
    selectTypeOption.set(YjsDatabaseKey.content, JSON.stringify({ disable_color: false, options: [] }));
    const expectRes = new Map([['another_single_select_field', rows]]);
    expect(groupByField(rows, rowMap, field)).toEqual(expectRes);
  });

  it('should handle empty selected ids', () => {
    const { fields, rowMap } = withTestingData();
    const cell = rowMap
      .get('1')
      ?.getMap(YjsEditorKey.data_section)
      ?.get(YjsEditorKey.database_row)
      ?.get(YjsDatabaseKey.cells)
      ?.get('single_select_field');
    cell?.set(YjsDatabaseKey.data, null);

    const field = fields.get('single_select_field');
    const result = groupByField(rows, rowMap, field);
    expect(result).toEqual(
      new Map([
        ['single_select_field', [{ id: '1', height: 37 }]],
        [
          '2',
          [
            { id: '2', height: 37 },
            { id: '5', height: 37 },
            { id: '8', height: 37 },
          ],
        ],
        [
          '3',
          [
            { id: '3', height: 37 },
            { id: '6', height: 37 },
            { id: '9', height: 37 },
          ],
        ],
        [
          '1',
          [
            { id: '4', height: 37 },
            { id: '7', height: 37 },
            { id: '10', height: 37 },
          ],
        ],
      ])
    );
  });
});
