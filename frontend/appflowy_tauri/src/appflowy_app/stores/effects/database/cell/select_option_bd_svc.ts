import { CellIdentifier } from './cell_bd_svc';
import {
  CellIdPB,
  CreateSelectOptionPayloadPB,
  RepeatedSelectOptionPayload,
  SelectOptionCellChangesetPB,
  SelectOptionPB,
} from '@/services/backend';
import {
  DatabaseEventCreateSelectOption,
  DatabaseEventDeleteSelectOption,
  DatabaseEventGetSelectOptionCellData,
  DatabaseEventInsertOrUpdateSelectOption,
  DatabaseEventUpdateSelectOptionCell,
} from '@/services/backend/events/flowy-database2';

export class SelectOptionBackendService {
  constructor(public readonly viewId: string, public readonly fieldId: string) {}

  createOption = async (params: { name: string }) => {
    const payload = CreateSelectOptionPayloadPB.fromObject({
      option_name: params.name,
      view_id: this.viewId,
      field_id: this.fieldId,
    });

    return DatabaseEventCreateSelectOption(payload);
  };
}

export class SelectOptionCellBackendService {
  constructor(public readonly cellIdentifier: CellIdentifier) {}

  // Creates a new option and insert this option to the cell
  createOption = async (params: { name: string; isSelect?: boolean }) => {
    const payload = CreateSelectOptionPayloadPB.fromObject({
      option_name: params.name,
      view_id: this.cellIdentifier.viewId,
      field_id: this.cellIdentifier.fieldId,
    });

    const result = await DatabaseEventCreateSelectOption(payload);
    if (result.ok) {
      return await this._insertOption(result.val, params.isSelect || true);
    } else {
      return result;
    }
  };

  private _insertOption = (option: SelectOptionPB, isSelect: boolean) => {
    const payload = RepeatedSelectOptionPayload.fromObject({
      view_id: this.cellIdentifier.viewId,
      field_id: this.cellIdentifier.fieldId,
      row_id: this.cellIdentifier.rowId,
    });
    payload.items.push(option);
    return DatabaseEventInsertOrUpdateSelectOption(payload);
  };

  updateOption = (option: SelectOptionPB) => {
    const payload = RepeatedSelectOptionPayload.fromObject({
      view_id: this.cellIdentifier.viewId,
      field_id: this.cellIdentifier.fieldId,
      row_id: this.cellIdentifier.rowId,
    });
    payload.items.push(option);
    return DatabaseEventInsertOrUpdateSelectOption(payload);
  };

  deleteOption = (options: SelectOptionPB[]) => {
    const payload = RepeatedSelectOptionPayload.fromObject({
      view_id: this.cellIdentifier.viewId,
      field_id: this.cellIdentifier.fieldId,
      row_id: this.cellIdentifier.rowId,
    });
    payload.items.push(...options);
    return DatabaseEventDeleteSelectOption(payload);
  };

  getOptionCellData = () => {
    return DatabaseEventGetSelectOptionCellData(this._cellIdentifier());
  };

  selectOption = (optionIds: string[]) => {
    const payload = SelectOptionCellChangesetPB.fromObject({ cell_identifier: this._cellIdentifier() });
    payload.insert_option_ids.push(...optionIds);
    return DatabaseEventUpdateSelectOptionCell(payload);
  };

  unselectOption = (optionIds: string[]) => {
    const payload = SelectOptionCellChangesetPB.fromObject({ cell_identifier: this._cellIdentifier() });
    payload.delete_option_ids.push(...optionIds);
    return DatabaseEventUpdateSelectOptionCell(payload);
  };

  private _cellIdentifier = () => {
    return CellIdPB.fromObject({
      view_id: this.cellIdentifier.viewId,
      field_id: this.cellIdentifier.fieldId,
      row_id: this.cellIdentifier.rowId,
    });
  };
}
