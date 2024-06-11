import { parseYDatabaseCellToCell } from '@/application/database-yjs/cell.parse';
import { expect } from '@jest/globals';
import { withTestingCheckboxCell, withTestingDateCell } from '@/application/database-yjs/__tests__/withTestingCell';
import * as Y from 'yjs';
import {
  FieldType,
  parseSelectOptionTypeOptions,
  parseRelationTypeOption,
  parseNumberTypeOptions,
} from '@/application/database-yjs';
import { YDatabaseField, YDatabaseFieldTypeOption, YjsDatabaseKey } from '@/application/collab.type';
import { withNumberTestingField, withRelationTestingField } from '@/application/database-yjs/__tests__/withTestingField';

describe('parseYDatabaseCellToCell', () => {
  it('should parse a DateTime cell', () => {
    const doc = new Y.Doc();
    const cell = withTestingDateCell();
    doc.getMap('cells').set('date_field', cell);
    const parsedCell = parseYDatabaseCellToCell(cell);
    expect(parsedCell.data).not.toBe(undefined);
    expect(parsedCell.createdAt).not.toBe(undefined);
    expect(parsedCell.lastModified).not.toBe(undefined);
    expect(parsedCell.fieldType).toBe(Number(FieldType.DateTime));
  });
  it('should parse a Checkbox cell', () => {
    const doc = new Y.Doc();
    const cell = withTestingCheckboxCell();
    doc.getMap('cells').set('checkbox_field', cell);
    const parsedCell = parseYDatabaseCellToCell(cell);
    expect(parsedCell.data).toBe(true);
    expect(parsedCell.createdAt).not.toBe(undefined);
    expect(parsedCell.lastModified).not.toBe(undefined);
    expect(parsedCell.fieldType).toBe(Number(FieldType.Checkbox));
  });
});

describe('Select option field parse', () => {
  it('should parse select option type options', () => {
    const doc = new Y.Doc();
    const field = new Y.Map() as YDatabaseField;
    const typeOption = new Y.Map() as YDatabaseFieldTypeOption;
    const now = Date.now().toString();

    field.set(YjsDatabaseKey.name, 'Single Select Field');
    field.set(YjsDatabaseKey.id, 'single_select_field');
    field.set(YjsDatabaseKey.type, String(FieldType.SingleSelect));
    field.set(YjsDatabaseKey.last_modified, now.valueOf());
    field.set(YjsDatabaseKey.type_option, typeOption);
    doc.getMap('fields').set('single_select_field', field);
    expect(parseSelectOptionTypeOptions(field)).toEqual(null);
  });
});

describe('number field parse', () => {
  it('should parse number field', () => {
    const doc = new Y.Doc();
    const field = withNumberTestingField();
    doc.getMap('fields').set('number_field', field);
    expect(parseNumberTypeOptions(field)).toEqual({
      format: 0,
    });
  });
});

describe('relation field parse', () => {
  it('should parse relation field', () => {
    const doc = new Y.Doc();
    const field = withRelationTestingField();
    doc.getMap('fields').set('relation_field', field);
    expect(parseRelationTypeOption(field)).toEqual(undefined);
  });
});
