import { CellPB, ChecklistCellDataPB, DateCellDataPB, FieldPB, FieldType, SelectOptionCellDataPB, URLCellDataPB } from '@/services/backend';
import type { Database } from './types';

export const fieldPbToField = (fieldPb: FieldPB): Database.Field => ({
  id: fieldPb.id,
  name: fieldPb.name,
  type: fieldPb.field_type,
  visibility: fieldPb.visibility,
  width: fieldPb.width,
  isPrimary: fieldPb.is_primary,
});

const toDateCellData = (pb: DateCellDataPB): Database.DateTimeCellData => ({
  date: pb.date,
  time: pb.time,
  timestamp: pb.timestamp,
  includeTime: pb.include_time,
});

const toSelectCellData = (pb: SelectOptionCellDataPB): Database.SelectCellData => {
  return {
    options: pb.options.map(option => ({
      id: option.id,
      name: option.name,
      color: option.color,
    })),
    selectOptions: pb.select_options.map(option => ({
      id: option.id,
      name: option.name,
      color: option.color,
    })),
  };
};

const toURLCellData = (pb: URLCellDataPB): Database.UrlCellData => ({
  url: pb.url,
  content: pb.content,
});

const toChecklistCellData = (pb: ChecklistCellDataPB): Database.ChecklistCellData => ({
  selectedOptions: pb.selected_options.map(({ id }) => id),
  percentage: pb.percentage,
});

function parseCellData(fieldType: FieldType, data: Uint8Array) {
  switch (fieldType) {
    case FieldType.RichText:
    case FieldType.Number:
    case FieldType.Checkbox:
      return new TextDecoder().decode(data);
    case FieldType.DateTime:
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return toDateCellData(DateCellDataPB.deserializeBinary(data));
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return toSelectCellData(SelectOptionCellDataPB.deserializeBinary(data));
    case FieldType.URL:
      return toURLCellData(URLCellDataPB.deserializeBinary(data));
    case FieldType.Checklist:
      return toChecklistCellData(ChecklistCellDataPB.deserializeBinary(data));
  }
}

export const cellPbToCell = (cellPb: CellPB, fieldType: FieldType): Database.Cell => {
  return {
    rowId: cellPb.row_id,
    fieldId: cellPb.field_id,
    fieldType: fieldType,
    data: parseCellData(fieldType, cellPb.data),
  };
};
