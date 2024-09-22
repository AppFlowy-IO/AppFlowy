import {
  RowId,
  YDatabaseFields,
  YDatabaseFilter,
  YDatabaseFilters,
  YDatabaseRow,
  YDoc,
  YjsDatabaseKey,
  YjsEditorKey,
} from '@/application/types';
import { FieldType } from '@/application/database-yjs/database.type';
import {
  CheckboxFilter,
  CheckboxFilterCondition,
  ChecklistFilter,
  ChecklistFilterCondition,
  DateFilter,
  NumberFilter,
  NumberFilterCondition,
  parseChecklistData,
  SelectOptionFilter,
  SelectOptionFilterCondition,
  TextFilter,
  TextFilterCondition,
} from '@/application/database-yjs/fields';
import { Row } from '@/application/database-yjs/selector';
import Decimal from 'decimal.js';
import { every, filter, some } from 'lodash-es';

export function parseFilter (fieldType: FieldType, filter: YDatabaseFilter) {
  const fieldId = filter.get(YjsDatabaseKey.field_id);
  const filterType = Number(filter.get(YjsDatabaseKey.filter_type));
  const id = filter.get(YjsDatabaseKey.id);
  const content = filter.get(YjsDatabaseKey.content);
  const condition = Number(filter.get(YjsDatabaseKey.condition));

  const value = {
    fieldId,
    filterType,
    condition,
    id,
    content,
  };

  switch (fieldType) {
    case FieldType.URL:
    case FieldType.RichText:
      return value as TextFilter;
    case FieldType.Number:
      return value as NumberFilter;
    case FieldType.Checklist:
      return value as ChecklistFilter;
    case FieldType.Checkbox:
      return value as CheckboxFilter;
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      // eslint-disable-next-line no-case-declarations
      const options = content.split(',');

      return {
        ...value,
        optionIds: options,
      } as SelectOptionFilter;
    case FieldType.DateTime:
    case FieldType.CreatedTime:
    case FieldType.LastEditedTime:
      return value as DateFilter;
  }

  return value;
}

function createPredicate (conditions: ((row: Row) => boolean)[]) {
  return function (item: Row) {
    return every(conditions, (condition) => condition(item));
  };
}

export function filterBy (rows: Row[], filters: YDatabaseFilters, fields: YDatabaseFields, rowMetas: Record<RowId, YDoc>) {
  const filterArray = filters.toArray();

  if (filterArray.length === 0 || Object.keys(rowMetas).length === 0 || fields.size === 0) return rows;

  const conditions = filterArray.map((filter) => {
    return (row: { id: string }) => {
      const fieldId = filter.get(YjsDatabaseKey.field_id);
      const field = fields.get(fieldId);
      const fieldType = Number(field.get(YjsDatabaseKey.type));
      const rowId = row.id;
      const rowMeta = rowMetas[rowId];

      if (!rowMeta) return false;
      const filterValue = parseFilter(fieldType, filter);
      const meta = rowMeta.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database_row) as YDatabaseRow;

      if (!meta) return false;

      const cells = meta.get(YjsDatabaseKey.cells);
      const cell = cells.get(fieldId);

      if (!cell) return false;
      const { condition, content } = filterValue;

      switch (fieldType) {
        case FieldType.URL:
        case FieldType.RichText:
          return textFilterCheck(cell.get(YjsDatabaseKey.data) as string, content, condition);
        case FieldType.Number:
          return numberFilterCheck(cell.get(YjsDatabaseKey.data) as string, content, condition);
        case FieldType.Checkbox:
          return checkboxFilterCheck(cell.get(YjsDatabaseKey.data) as string, condition);
        case FieldType.SingleSelect:
        case FieldType.MultiSelect:
          return selectOptionFilterCheck(cell.get(YjsDatabaseKey.data) as string, content, condition);
        case FieldType.Checklist:
          return checklistFilterCheck(cell.get(YjsDatabaseKey.data) as string, content, condition);
        default:
          return true;
      }
    };
  });
  const predicate = createPredicate(conditions);

  return filter(rows, predicate);
}

export function textFilterCheck (data: string, content: string, condition: TextFilterCondition) {
  switch (condition) {
    case TextFilterCondition.TextContains:
      return data.includes(content);
    case TextFilterCondition.TextDoesNotContain:
      return !data.includes(content);
    case TextFilterCondition.TextIs:
      return data === content;
    case TextFilterCondition.TextIsNot:
      return data !== content;
    case TextFilterCondition.TextIsEmpty:
      return data === '';
    case TextFilterCondition.TextIsNotEmpty:
      return data !== '';
    default:
      return false;
  }
}

export function numberFilterCheck (data: string, content: string, condition: number) {
  if (isNaN(Number(data)) || isNaN(Number(content)) || data === '' || content === '') {
    if (condition === NumberFilterCondition.NumberIsEmpty) {
      return data === '';
    }

    if (condition === NumberFilterCondition.NumberIsNotEmpty) {
      return data !== '';
    }

    return false;
  }

  const decimal = new Decimal(data).toNumber();
  const filterDecimal = new Decimal(content).toNumber();

  switch (condition) {
    case NumberFilterCondition.Equal:
      return decimal === filterDecimal;
    case NumberFilterCondition.NotEqual:
      return decimal !== filterDecimal;
    case NumberFilterCondition.GreaterThan:
      return decimal > filterDecimal;
    case NumberFilterCondition.GreaterThanOrEqualTo:
      return decimal >= filterDecimal;
    case NumberFilterCondition.LessThan:
      return decimal < filterDecimal;
    case NumberFilterCondition.LessThanOrEqualTo:
      return decimal <= filterDecimal;
    default:
      return false;
  }
}

export function checkboxFilterCheck (data: string, condition: number) {
  switch (condition) {
    case CheckboxFilterCondition.IsChecked:
      return data === 'Yes';
    case CheckboxFilterCondition.IsUnChecked:
      return data !== 'Yes';
    default:
      return false;
  }
}

export function checklistFilterCheck (data: string, content: string, condition: number) {
  const percentage = parseChecklistData(data)?.percentage ?? 0;

  if (condition === ChecklistFilterCondition.IsComplete) {
    return percentage === 1;
  }

  return percentage !== 1;
}

export function selectOptionFilterCheck (data: string, content: string, condition: number) {
  if (SelectOptionFilterCondition.OptionIsEmpty === condition) {
    return data === '';
  }

  if (SelectOptionFilterCondition.OptionIsNotEmpty === condition) {
    return data !== '';
  }

  const selectedOptionIds = data.split(',');
  const filterOptionIds = content.split(',');

  switch (condition) {
    // Ensure all filterOptionIds are included in selectedOptionIds
    case SelectOptionFilterCondition.OptionIs:
      return every(filterOptionIds, (option) => selectedOptionIds.includes(option));

    // Ensure none of the filterOptionIds are included in selectedOptionIds
    case SelectOptionFilterCondition.OptionIsNot:
      return every(filterOptionIds, (option) => !selectedOptionIds.includes(option));

    // Ensure at least one of the filterOptionIds is included in selectedOptionIds
    case SelectOptionFilterCondition.OptionContains:
      return some(filterOptionIds, (option) => selectedOptionIds.includes(option));

    // Ensure at least one of the filterOptionIds is not included in selectedOptionIds
    case SelectOptionFilterCondition.OptionDoesNotContain:
      return some(filterOptionIds, (option) => !selectedOptionIds.includes(option));

    // Default case, if no conditions match
    default:
      return false;
  }
}
