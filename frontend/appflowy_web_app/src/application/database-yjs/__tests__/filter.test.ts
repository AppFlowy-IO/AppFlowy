import {
  NumberFilterCondition,
  TextFilterCondition,
  CheckboxFilterCondition,
  ChecklistFilterCondition,
  SelectOptionFilterCondition,
  Row,
} from '@/application/database-yjs';
import { withTestingData } from '@/application/database-yjs/__tests__/withTestingData';
import {
  withCheckboxFilter,
  withChecklistFilter,
  withDateTimeFilter,
  withMultiSelectOptionFilter,
  withNumberFilter,
  withRichTextFilter,
  withSingleSelectOptionFilter,
  withUrlFilter,
} from '@/application/database-yjs/__tests__/withTestingFilters';
import { withTestingRows } from '@/application/database-yjs/__tests__/withTestingRows';
import {
  textFilterCheck,
  numberFilterCheck,
  checkboxFilterCheck,
  checklistFilterCheck,
  selectOptionFilterCheck,
  filterBy,
} from '../filter';
import { expect } from '@jest/globals';
import * as Y from 'yjs';

describe('Text filter check', () => {
  const text = 'Hello, world!';
  it('should return true for TextIs condition', () => {
    const condition = TextFilterCondition.TextIs;
    const content = 'Hello, world!';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for TextIs condition', () => {
    const condition = TextFilterCondition.TextIs;
    const content = 'Hello, world';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for TextIsNot condition', () => {
    const condition = TextFilterCondition.TextIsNot;
    const content = 'Hello, world';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for TextIsNot condition', () => {
    const condition = TextFilterCondition.TextIsNot;
    const content = 'Hello, world!';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for TextContains condition', () => {
    const condition = TextFilterCondition.TextContains;
    const content = 'world';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for TextContains condition', () => {
    const condition = TextFilterCondition.TextContains;
    const content = 'planet';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for TextDoesNotContain condition', () => {
    const condition = TextFilterCondition.TextDoesNotContain;
    const content = 'planet';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for TextDoesNotContain condition', () => {
    const condition = TextFilterCondition.TextDoesNotContain;
    const content = 'world';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for TextIsEmpty condition', () => {
    const condition = TextFilterCondition.TextIsEmpty;
    const text = '';

    const result = textFilterCheck(text, '', condition);

    expect(result).toBe(true);
  });

  it('should return false for TextIsEmpty condition', () => {
    const condition = TextFilterCondition.TextIsEmpty;
    const text = 'Hello, world!';

    const result = textFilterCheck(text, '', condition);

    expect(result).toBe(false);
  });

  it('should return true for TextIsNotEmpty condition', () => {
    const condition = TextFilterCondition.TextIsNotEmpty;
    const text = 'Hello, world!';

    const result = textFilterCheck(text, '', condition);

    expect(result).toBe(true);
  });

  it('should return false for TextIsNotEmpty condition', () => {
    const condition = TextFilterCondition.TextIsNotEmpty;
    const text = '';

    const result = textFilterCheck(text, '', condition);

    expect(result).toBe(false);
  });

  it('should return false for unknown condition', () => {
    const condition = 42;
    const content = 'Hello, world!';

    const result = textFilterCheck(text, content, condition);

    expect(result).toBe(false);
  });
});

describe('Number filter check', () => {
  const num = '42';
  it('should return true for Equal condition', () => {
    const condition = NumberFilterCondition.Equal;
    const content = '42';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for Equal condition', () => {
    const condition = NumberFilterCondition.Equal;
    const content = '43';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for NotEqual condition', () => {
    const condition = NumberFilterCondition.NotEqual;
    const content = '43';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for NotEqual condition', () => {
    const condition = NumberFilterCondition.NotEqual;
    const content = '42';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for GreaterThan condition', () => {
    const condition = NumberFilterCondition.GreaterThan;
    const content = '41';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for GreaterThan condition', () => {
    const condition = NumberFilterCondition.GreaterThan;
    const content = '42';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for GreaterThanOrEqualTo condition', () => {
    const condition = NumberFilterCondition.GreaterThanOrEqualTo;
    const content = '42';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for GreaterThanOrEqualTo condition', () => {
    const condition = NumberFilterCondition.GreaterThanOrEqualTo;
    const content = '43';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for LessThan condition', () => {
    const condition = NumberFilterCondition.LessThan;
    const content = '43';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for LessThan condition', () => {
    const condition = NumberFilterCondition.LessThan;
    const content = '42';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for LessThanOrEqualTo condition', () => {
    const condition = NumberFilterCondition.LessThanOrEqualTo;
    const content = '42';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for LessThanOrEqualTo condition', () => {
    const condition = NumberFilterCondition.LessThanOrEqualTo;
    const content = '41';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for NumberIsEmpty condition', () => {
    const condition = NumberFilterCondition.NumberIsEmpty;

    const result = numberFilterCheck('', '', condition);

    expect(result).toBe(true);
  });

  it('should return false for NumberIsEmpty condition', () => {
    const condition = NumberFilterCondition.NumberIsEmpty;
    const num = '42';

    const result = numberFilterCheck(num, '', condition);

    expect(result).toBe(false);
  });

  it('should return true for NumberIsNotEmpty condition', () => {
    const condition = NumberFilterCondition.NumberIsNotEmpty;
    const num = '42';

    const result = numberFilterCheck(num, '', condition);

    expect(result).toBe(true);
  });

  it('should return false for NumberIsNotEmpty condition', () => {
    const condition = NumberFilterCondition.NumberIsNotEmpty;
    const num = '';

    const result = numberFilterCheck(num, '', condition);

    expect(result).toBe(false);
  });

  it('should return false for unknown condition', () => {
    const condition = 42;
    const content = '42';

    const result = numberFilterCheck(num, content, condition);

    expect(result).toBe(false);
  });
});

describe('Checkbox filter check', () => {
  it('should return true for IsChecked condition', () => {
    const condition = CheckboxFilterCondition.IsChecked;
    const data = 'Yes';

    const result = checkboxFilterCheck(data, condition);

    expect(result).toBe(true);
  });

  it('should return false for IsChecked condition', () => {
    const condition = CheckboxFilterCondition.IsChecked;
    const data = 'No';

    const result = checkboxFilterCheck(data, condition);

    expect(result).toBe(false);
  });

  it('should return true for IsUnChecked condition', () => {
    const condition = CheckboxFilterCondition.IsUnChecked;
    const data = 'No';

    const result = checkboxFilterCheck(data, condition);

    expect(result).toBe(true);
  });

  it('should return false for IsUnChecked condition', () => {
    const condition = CheckboxFilterCondition.IsUnChecked;
    const data = 'Yes';

    const result = checkboxFilterCheck(data, condition);

    expect(result).toBe(false);
  });

  it('should return false for unknown condition', () => {
    const condition = 42;
    const data = 'Yes';

    const result = checkboxFilterCheck(data, condition);

    expect(result).toBe(false);
  });
});

describe('Checklist filter check', () => {
  it('should return true for IsComplete condition', () => {
    const condition = ChecklistFilterCondition.IsComplete;
    const data = JSON.stringify({
      options: [
        { id: '1', name: 'Option 1' },
        { id: '2', name: 'Option 2' },
      ],
      selected_option_ids: ['1', '2'],
    });

    const result = checklistFilterCheck(data, '', condition);

    expect(result).toBe(true);
  });

  it('should return false for IsComplete condition', () => {
    const condition = ChecklistFilterCondition.IsComplete;
    const data = JSON.stringify({
      options: [
        { id: '1', name: 'Option 1' },
        { id: '2', name: 'Option 2' },
      ],
      selected_option_ids: ['1'],
    });

    const result = checklistFilterCheck(data, '', condition);

    expect(result).toBe(false);
  });

  it('should return false for unknown condition', () => {
    const condition = 42;
    const data = JSON.stringify({
      options: [
        { id: '1', name: 'Option 1' },
        { id: '2', name: 'Option 2' },
      ],
      selected_option_ids: ['1', '2'],
    });

    const result = checklistFilterCheck(data, '', condition);

    expect(result).toBe(false);
  });
});

describe('SelectOption filter check', () => {
  it('should return true for OptionIs condition', () => {
    const condition = SelectOptionFilterCondition.OptionIs;
    const content = '1';
    const data = '1,2';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for OptionIs condition', () => {
    const condition = SelectOptionFilterCondition.OptionIs;
    const content = '3';
    const data = '1,2';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for OptionIsNot condition', () => {
    const condition = SelectOptionFilterCondition.OptionIsNot;
    const content = '3';
    const data = '1,2';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for OptionIsNot condition', () => {
    const condition = SelectOptionFilterCondition.OptionIsNot;
    const content = '1';
    const data = '1,2';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for OptionContains condition', () => {
    const condition = SelectOptionFilterCondition.OptionContains;
    const content = '1,3';
    const data = '1,2,3';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for OptionContains condition', () => {
    const condition = SelectOptionFilterCondition.OptionContains;
    const content = '4';
    const data = '1,2,3';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for OptionDoesNotContain condition', () => {
    const condition = SelectOptionFilterCondition.OptionDoesNotContain;
    const content = '4,5';
    const data = '1,2,3';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(true);
  });

  it('should return false for OptionDoesNotContain condition', () => {
    const condition = SelectOptionFilterCondition.OptionDoesNotContain;
    const content = '1,3';
    const data = '1,2,3';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(false);
  });

  it('should return true for OptionIsEmpty condition', () => {
    const condition = SelectOptionFilterCondition.OptionIsEmpty;
    const data = '';

    const result = selectOptionFilterCheck(data, '', condition);

    expect(result).toBe(true);
  });

  it('should return false for OptionIsEmpty condition', () => {
    const condition = SelectOptionFilterCondition.OptionIsEmpty;
    const data = '1,2';

    const result = selectOptionFilterCheck(data, '', condition);

    expect(result).toBe(false);
  });

  it('should return true for OptionIsNotEmpty condition', () => {
    const condition = SelectOptionFilterCondition.OptionIsNotEmpty;
    const data = '1,2';

    const result = selectOptionFilterCheck(data, '', condition);

    expect(result).toBe(true);
  });

  it('should return false for OptionIsNotEmpty condition', () => {
    const condition = SelectOptionFilterCondition.OptionIsNotEmpty;
    const data = '';

    const result = selectOptionFilterCheck(data, '', condition);

    expect(result).toBe(false);
  });

  it('should return false for unknown condition', () => {
    const condition = 42;
    const content = '1';
    const data = '1,2';

    const result = selectOptionFilterCheck(data, content, condition);

    expect(result).toBe(false);
  });
});

describe('Database filterBy', () => {
  let rows: Row[];

  beforeEach(() => {
    rows = withTestingRows();
  });

  it('should return all rows for empty filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('1,2,3,4,5,6,7,8,9,10');
  });

  it('should return all rows for empty rowMap', () => {
    const { filters, fields } = withTestingData();
    const rowMap = new Y.Map() as Y.Map<Y.Doc>;
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('1,2,3,4,5,6,7,8,9,10');
  });

  it('should return rows that match text filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withRichTextFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('1,5');
  });

  it('should return rows that match number filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withNumberFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('4,5,6,7,8,9,10');
  });

  it('should return rows that match checkbox filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withCheckboxFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('2,4,6,8,10');
  });

  it('should return rows that match checklist filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withChecklistFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('1,2,4,5,6,7,8,10');
  });

  it('should return rows that match multiple filters', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter1 = withRichTextFilter();
    const filter2 = withNumberFilter();
    filters.push([filter1, filter2]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('5');
  });

  it('should return rows that match url filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withUrlFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('4');
  });

  it('should return rows that match date filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withDateTimeFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('1,2,3,4,5,6,7,8,9,10');
  });

  it('should return rows that match select option filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withSingleSelectOptionFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('2,5,8');
  });

  it('should return rows that match multi select option filter', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter = withMultiSelectOptionFilter();
    filters.push([filter]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('1,2,3,5,6,7,8,9');
  });

  it('should return rows that match multiple filters', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter1 = withNumberFilter();
    const filter2 = withChecklistFilter();
    filters.push([filter1, filter2]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('4,5,6,7,8,10');
  });

  it('should return empty array for all filters', () => {
    const { filters, fields, rowMap } = withTestingData();
    const filter1 = withNumberFilter();
    const filter2 = withChecklistFilter();
    const filter3 = withRichTextFilter();
    const filter4 = withCheckboxFilter();
    const filter5 = withSingleSelectOptionFilter();
    const filter6 = withMultiSelectOptionFilter();
    const filter7 = withUrlFilter();
    const filter8 = withDateTimeFilter();
    filters.push([filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8]);
    const result = filterBy(rows, filters, fields, rowMap)
      .map((row) => row.id)
      .join(',');
    expect(result).toBe('');
  });
});
