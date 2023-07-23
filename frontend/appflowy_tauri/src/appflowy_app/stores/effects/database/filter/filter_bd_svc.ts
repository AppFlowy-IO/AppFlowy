import {
  CheckboxFilterPB,
  DatabaseSettingChangesetPB,
  DatabaseViewIdPB,
  DeleteFilterPayloadPB,
  FieldType,
  FilterPB,
  FlowyError,
  RepeatedFilterPB,
  SelectOptionFilterPB,
  TextFilterPB,
  UpdateFilterPayloadPB,
} from '@/services/backend';
import {
  DatabaseEventGetAllFilters,
  DatabaseEventUpdateDatabaseSetting,
} from '@/services/backend/events/flowy-database2';
import { Err, Ok, Result } from 'ts-results';

export class FilterBackendService {
  constructor(public readonly viewId: string) {}

  getFilters = async (): Promise<Result<FilterPB[], FlowyError>> => {
    const payload = DatabaseViewIdPB.fromObject({
      value: this.viewId,
    });

    let filtersPB: FilterPB[] = [];

    const res = await DatabaseEventGetAllFilters(payload);

    if (res.ok) {
      filtersPB = res.val.items;

      return Ok(filtersPB);
    } else {
      return Err(res.val);
    }
  };

  addFilter = (
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
