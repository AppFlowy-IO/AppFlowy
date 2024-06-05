import { Row } from '@/application/database-yjs';
import { withTestingData } from '@/application/database-yjs/__tests__/withTestingData';
import { withTestingRows } from '@/application/database-yjs/__tests__/withTestingRows';
import { expect } from '@jest/globals';
import { groupByField } from '../group';

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
});
