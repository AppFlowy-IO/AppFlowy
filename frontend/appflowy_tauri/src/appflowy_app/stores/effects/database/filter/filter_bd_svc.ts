import {
  CheckboxFilterPB,
  DatabaseSettingChangesetPB,
  DatabaseViewIdPB,
  DeleteFilterPayloadPB,
  FieldType,
  FilterPB,
  FlowyError,
  SelectOptionFilterPB,
  TextFilterPB,
  UpdateFilterPayloadPB,
} from '@/services/backend';
import {
  DatabaseEventGetAllFilters,
  DatabaseEventUpdateDatabaseSetting,
} from '@/services/backend/events/flowy-database2';
import { Err, Ok, Result } from 'ts-results';
import { nanoid } from 'nanoid';

export class FilterBackendService {
  constructor(public readonly viewId: string) {}

  getFilters = async (): Promise<Result<FilterParsed[], FlowyError>> => {
    const payload = DatabaseViewIdPB.fromObject({
      value: this.viewId,
    });

    const res = await DatabaseEventGetAllFilters(payload);

    if (res.ok) {
      return Ok(res.val.items.map<FilterParsed>((f) => new FilterParsed(this.viewId, f)));
    } else {
      return Err(res.val);
    }
  };

  addFilter = async (
    fieldId: string,
    fieldType: FieldType,
    filter: TextFilterPB | SelectOptionFilterPB | CheckboxFilterPB
  ) => {
    const data = filter.serializeBinary();
    const id = nanoid(4);

    await DatabaseEventUpdateDatabaseSetting(
      DatabaseSettingChangesetPB.fromObject({
        view_id: this.viewId,
        update_filter: UpdateFilterPayloadPB.fromObject({
          filter_id: id,
          view_id: this.viewId,
          field_id: fieldId,
          field_type: fieldType,
          data,
        }),
      })
    );
    return id;
  };

  updateFilter = (
    filterId: string,
    fieldId: string,
    fieldType: FieldType,
    filter: TextFilterPB | SelectOptionFilterPB | CheckboxFilterPB
  ) => {
    const data = filter.serializeBinary();

    return DatabaseEventUpdateDatabaseSetting(
      DatabaseSettingChangesetPB.fromObject({
        view_id: this.viewId,
        update_filter: UpdateFilterPayloadPB.fromObject({
          view_id: this.viewId,
          field_id: fieldId,
          field_type: fieldType,
          filter_id: filterId,
          data,
        }),
      })
    );
  };

  removeFilter = (fieldId: string, fieldType: FieldType, filterId: string) => {
    return DatabaseEventUpdateDatabaseSetting(
      DatabaseSettingChangesetPB.fromObject({
        view_id: this.viewId,
        delete_filter: DeleteFilterPayloadPB.fromObject({
          view_id: this.viewId,
          field_id: fieldId,
          field_type: fieldType,
          filter_id: filterId,
        }),
      })
    );
  };
}

export class FilterParsed {
  view_id: string;
  id: string;
  field_id: string;
  field_type: FieldType;
  data: TextFilterPB | SelectOptionFilterPB | CheckboxFilterPB | Uint8Array;

  constructor(view_id: string, filter: FilterPB) {
    this.view_id = view_id;

    this.id = filter.id;
    this.field_id = filter.field_id;
    this.field_type = filter.field_type;

    switch (filter.field_type) {
      case FieldType.RichText:
        this.data = TextFilterPB.deserializeBinary(filter.data);
        break;
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        this.data = SelectOptionFilterPB.deserializeBinary(filter.data);
        break;
      case FieldType.Checkbox:
        this.data = CheckboxFilterPB.deserializeBinary(filter.data);
        break;
      default:
        this.data = filter.data;
        break;
    }
  }
}
