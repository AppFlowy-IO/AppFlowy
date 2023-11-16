import {
  CellIdPB,
  CellChangesetPB,
  SelectOptionCellChangesetPB,
  ChecklistCellDataChangesetPB,
  DateChangesetPB,
  FieldType,
} from '@/services/backend';
import {
  DatabaseEventGetCell,
  DatabaseEventUpdateCell,
  DatabaseEventUpdateSelectOptionCell,
  DatabaseEventUpdateChecklistCell,
  DatabaseEventUpdateDateCell,
} from '@/services/backend/events/flowy-database2';
import { SelectOption } from '../field';
import { Cell, pbToCell } from './cell_types';

export async function getCell(viewId: string, rowId: string, fieldId: string, fieldType?: FieldType): Promise<Cell> {
  const payload = CellIdPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
  });

  const result = await DatabaseEventGetCell(payload);

  return result.map(value => pbToCell(value, fieldType)).unwrap();
}

export async function updateCell(viewId: string, rowId: string, fieldId: string, changeset: string): Promise<void> {
  const payload = CellChangesetPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
    cell_changeset: changeset,
  });

  const result = await DatabaseEventUpdateCell(payload);

  return result.unwrap();
}

export async function updateSelectCell(
  viewId: string,
  rowId: string,
  fieldId: string,
  data: {
    insertOptionIds?: string[];
    deleteOptionIds?: string[];
  },
): Promise<void> {
  const payload = SelectOptionCellChangesetPB.fromObject({
    cell_identifier: {
      view_id: viewId,
      row_id: rowId,
      field_id: fieldId,
    },
    insert_option_ids: data.insertOptionIds,
    delete_option_ids: data.deleteOptionIds,
  });

  const result = await DatabaseEventUpdateSelectOptionCell(payload);

  return result.unwrap();
}

export async function updateChecklistCell(
  viewId: string,
  rowId: string,
  fieldId: string,
  data: {
    insertOptions?: string[];
    selectedOptionIds?: string[];
    deleteOptionIds?: string[];
    updateOptions?: Partial<SelectOption>[];
  },
): Promise<void> {
  const payload = ChecklistCellDataChangesetPB.fromObject({
    view_id: viewId,
    row_id: rowId,
    field_id: fieldId,
    insert_options: data.insertOptions,
    selected_option_ids: data.selectedOptionIds,
    delete_option_ids: data.deleteOptionIds,
    update_options: data.updateOptions,
  });

  const result = await DatabaseEventUpdateChecklistCell(payload);

  return result.unwrap();
}

export async function updateDateCell(
  viewId: string,
  rowId: string,
  fieldId: string,
  data: {
    date?: number;
    time?: string;
    includeTime?: boolean;
    clearFlag?: boolean;
  },
): Promise<void> {
  const payload = DateChangesetPB.fromObject({
    cell_id: {
      view_id: viewId,
      row_id: rowId,
      field_id: fieldId,
    },
    date: data.date,
    time: data.time,
    include_time: data.includeTime,
    clear_flag: data.clearFlag,
  });

  const result = await DatabaseEventUpdateDateCell(payload);

  return result.unwrap();
}
