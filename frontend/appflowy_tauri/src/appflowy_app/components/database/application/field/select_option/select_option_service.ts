import {
  CreateSelectOptionPayloadPB,
  RepeatedSelectOptionPayload,
} from '@/services/backend';
import {
  DatabaseEventCreateSelectOption,
  DatabaseEventInsertOrUpdateSelectOption,
  DatabaseEventDeleteSelectOption,
} from '@/services/backend/events/flowy-database2';
import { pbToSelectOption, SelectOption } from './select_option_types';

export async function createSelectOption(viewId: string, fieldId: string, optionName: string): Promise<SelectOption> {
  const payload = CreateSelectOptionPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
    option_name: optionName,
  });

  const result = await DatabaseEventCreateSelectOption(payload);

  return result.map(pbToSelectOption).unwrap();
}

/**
 * @param [rowId] If pass the rowId, the cell will select this option after insert or update.
 */
export async function insertOrUpdateSelectOption(
  viewId: string,
  fieldId: string,
  items: Partial<SelectOption>[],
  rowId?: string,
): Promise<void> {
  const payload = RepeatedSelectOptionPayload.fromObject({
    view_id: viewId,
    field_id: fieldId,
    row_id: rowId,
    items: items,
  });

  const result = await DatabaseEventInsertOrUpdateSelectOption(payload);

  return result.unwrap();
}

export async function deleteSelectOption(
  viewId: string,
  fieldId: string,
  items: Partial<SelectOption>[],
  rowId?: string,
): Promise<void> {
  const payload = RepeatedSelectOptionPayload.fromObject({
    view_id: viewId,
    field_id: fieldId,
    row_id: rowId,
    items: items,
  });

  const result = await DatabaseEventDeleteSelectOption(payload);

  return result.unwrap();
}
