import {
  DatabaseSettingChangesetPB,
  DatabaseViewIdPB,
  DeleteSortPayloadPB,
  FieldType,
  FlowyError,
  SortConditionPB,
  UpdateSortPayloadPB,
} from '@/services/backend';
import { DatabaseEventGetAllSorts, DatabaseEventUpdateDatabaseSetting } from '@/services/backend/events/flowy-database2';
import { Err, Ok, Result } from 'ts-results';
import { nanoid } from 'nanoid';
import type { IDatabaseSort } from '$app_reducers/database/slice';

export class SortBackendService {
  constructor(public readonly viewId: string) {}

  getSorts = async (): Promise<Result<IDatabaseSort[], FlowyError>> => {
    const payload = DatabaseViewIdPB.fromObject({
      value: this.viewId,
    });

    const res = await DatabaseEventGetAllSorts(payload);

    if (res.ok) {
      return Ok(
        res.val.items.map<IDatabaseSort>((o) => ({
          id: o.id,
          fieldId: o.field_id,
          fieldType: o.field_type,
          order: o.condition,
        }))
      );
    } else {
      return Err(res.val);
    }
  };

  addSort = async (fieldId: string, fieldType: FieldType, order: SortConditionPB) => {
    const id = nanoid(4);

    await DatabaseEventUpdateDatabaseSetting(
      DatabaseSettingChangesetPB.fromObject({
        view_id: this.viewId,
        update_sort: UpdateSortPayloadPB.fromObject({
          view_id: this.viewId,
          field_id: fieldId,
          field_type: fieldType,
          sort_id: id,
          condition: order,
        }),
      })
    );
    return id;
  };

  updateSort = (sortId: string, fieldId: string, fieldType: FieldType, order: SortConditionPB) => {
    return DatabaseEventUpdateDatabaseSetting(
      DatabaseSettingChangesetPB.fromObject({
        view_id: this.viewId,
        update_sort: UpdateSortPayloadPB.fromObject({
          view_id: this.viewId,
          field_id: fieldId,
          field_type: fieldType,
          sort_id: sortId,
          condition: order,
        }),
      })
    );
  };

  removeSort = (fieldId: string, fieldType: FieldType, sortId: string) => {
    return DatabaseEventUpdateDatabaseSetting(
      DatabaseSettingChangesetPB.fromObject({
        view_id: this.viewId,
        delete_sort: DeleteSortPayloadPB.fromObject({
          view_id: this.viewId,
          field_id: fieldId,
          field_type: fieldType,
          sort_id: sortId,
        }),
      })
    );
  };
}
