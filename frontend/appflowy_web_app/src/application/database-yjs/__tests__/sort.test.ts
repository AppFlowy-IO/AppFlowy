import { Row } from '@/application/database-yjs';
import { withTestingData } from '@/application/database-yjs/__tests__/withTestingData';
import { withTestingRows } from '@/application/database-yjs/__tests__/withTestingRows';
import {
  withCheckboxSort,
  withChecklistSort,
  withDateTimeSort,
  withMultiSelectOptionSort,
  withNumberSort,
  withRichTextSort,
  withSingleSelectOptionSort,
  withUrlSort,
} from '@/application/database-yjs/__tests__/withTestingSorts';
import {
  withCheckboxTestingField,
  withDateTimeTestingField,
  withNumberTestingField,
  withRichTextTestingField,
  withSelectOptionTestingField,
  withURLTestingField,
  withChecklistTestingField,
} from './withTestingField';
import { sortBy, parseCellDataForSort } from '../sort';
import * as Y from 'yjs';
import { expect } from '@jest/globals';

describe('parseCellDataForSort', () => {
  it('should parse data correctly based on field type', () => {
    const doc = new Y.Doc();
    const field = withNumberTestingField();
    doc.getMap().set('field', field);
    const data = 42;

    const result = parseCellDataForSort(field, data);

    expect(result).toEqual(data);
  });

  it('should return default value for empty rich text', () => {
    const doc = new Y.Doc();
    const field = withRichTextTestingField();
    doc.getMap().set('field', field);
    const data = '';

    const result = parseCellDataForSort(field, data);

    expect(result).toEqual('\uFFFF');
  });

  it('should return default value for empty URL', () => {
    const doc = new Y.Doc();
    const field = withURLTestingField();
    doc.getMap().set('field', field);
    const data = '';

    const result = parseCellDataForSort(field, data);

    expect(result).toBe('\uFFFF');
  });

  it('should return data for non-empty rich text', () => {
    const doc = new Y.Doc();
    const field = withRichTextTestingField();
    doc.getMap().set('field', field);
    const data = 'Hello, world!';

    const result = parseCellDataForSort(field, data);

    expect(result).toBe(data);
  });

  it('should parse checkbox data correctly', () => {
    const doc = new Y.Doc();
    const field = withCheckboxTestingField();
    doc.getMap().set('field', field);
    const data = 'Yes';

    const result = parseCellDataForSort(field, data);

    expect(result).toBe(true);

    const noData = 'No';
    const noResult = parseCellDataForSort(field, noData);
    expect(noResult).toBe(false);
  });

  it('should parse DateTime data correctly', () => {
    const doc = new Y.Doc();
    const field = withDateTimeTestingField();
    doc.getMap().set('field', field);
    const data = '1633046400000';

    const result = parseCellDataForSort(field, data);

    expect(result).toBe(Number(data));
  });

  it('should parse SingleSelect data correctly', () => {
    const doc = new Y.Doc();
    const field = withSelectOptionTestingField();
    doc.getMap().set('field', field);
    const data = '1';

    const result = parseCellDataForSort(field, data);

    expect(result).toBe('Option 1');
  });

  it('should parse MultiSelect data correctly', () => {
    const doc = new Y.Doc();
    const field = withSelectOptionTestingField();
    doc.getMap().set('field', field);
    const data = '1,2';

    const result = parseCellDataForSort(field, data);

    expect(result).toBe('Option 1, Option 2');
  });

  it('should parse Checklist data correctly', () => {
    const doc = new Y.Doc();
    const field = withChecklistTestingField();
    doc.getMap().set('field', field);
    const data = '[]';

    const result = parseCellDataForSort(field, data);

    expect(result).toBe(0);
  });
});

describe('Database sortBy', () => {
  let rows: Row[];

  beforeEach(() => {
    rows = withTestingRows();
  });

  it('should sort by number field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withNumberSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('1,2,3,4,5,6,7,8,9,10');
  });

  it('should sort by number field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withNumberSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('10,9,8,7,6,5,4,3,2,1');
  });

  it('should sort by rich text field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withRichTextSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('9,2,3,4,1,6,10,8,5,7');
  });

  it('should sort by rich text field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withRichTextSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('7,5,8,10,6,1,4,3,2,9');
  });

  it('should sort by url field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withUrlSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('1,10,2,3,4,5,6,7,8,9');
  });

  it('should sort by url field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withUrlSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('9,8,7,6,5,4,3,2,10,1');
  });

  it('should sort by checkbox field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withCheckboxSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('2,4,6,8,10,1,3,5,7,9');
  });

  it('should sort by checkbox field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withCheckboxSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('1,3,5,7,9,2,4,6,8,10');
  });

  it('should sort by DateTime field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withDateTimeSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('1,2,3,4,5,6,7,8,9,10');
  });

  it('should sort by DateTime field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withDateTimeSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('10,9,8,7,6,5,4,3,2,1');
  });

  it('should sort by SingleSelect field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withSingleSelectOptionSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('1,4,7,10,2,5,8,3,6,9');
  });

  it('should sort by SingleSelect field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withSingleSelectOptionSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('3,6,9,2,5,8,1,4,7,10');
  });

  it('should sort by MultiSelect field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withMultiSelectOptionSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('1,7,5,3,6,9,4,10,2,8');
  });

  it('should sort by MultiSelect field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withMultiSelectOptionSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('2,8,4,10,3,6,9,5,1,7');
  });

  it('should sort by Checklist field in ascending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withChecklistSort();
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('4,10,1,2,5,6,7,8,3,9');
  });

  it('should sort by Checklist field in descending order', () => {
    const { sorts, fields, rowMap } = withTestingData();
    const sort = withChecklistSort(false);
    sorts.push([sort]);

    const sortedRows = sortBy(rows, sorts, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(sortedRows).toBe('3,9,1,2,5,6,7,8,4,10');
  });
});
