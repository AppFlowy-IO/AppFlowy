import { DatabaseFieldChangesetPB, FieldSettingsPB, FieldVisibility } from '@/services/backend';
import { Database, fieldService } from '$app/application/database';
import { didDeleteCells, didUpdateCells } from '$app/application/database/cell/cell_listeners';

export function didUpdateFieldSettings(database: Database, settings: FieldSettingsPB) {
  const { field_id: fieldId, visibility, width } = settings;
  const field = database.fields.find((field) => field.id === fieldId);

  if (!field) return;
  field.visibility = visibility;
  field.width = width;
  // delete cells if field is hidden
  if (visibility === FieldVisibility.AlwaysHidden) {
    didDeleteCells({ database, fieldId });
  }
}

export async function didUpdateFields(viewId: string, database: Database, changeset: DatabaseFieldChangesetPB) {
  const { fields, typeOptions } = await fieldService.getFields(viewId);

  database.fields = fields;
  const deletedFieldIds = Object.keys(changeset.deleted_fields);
  const updatedFieldIds = changeset.updated_fields.map((field) => field.id);

  Object.assign(database.typeOptions, typeOptions);
  deletedFieldIds.forEach(
    (fieldId) => {
      // delete cache cells
      didDeleteCells({ database, fieldId });
      // delete cache type options
      delete database.typeOptions[fieldId];
    },
    [database.typeOptions]
  );

  updatedFieldIds.forEach((fieldId) => {
    // delete cache cells
    void didUpdateCells({ viewId, database, fieldId });
  });
}
