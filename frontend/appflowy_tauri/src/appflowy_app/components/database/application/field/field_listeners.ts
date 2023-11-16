import { FieldSettingsPB } from '@/services/backend';
import { Database } from '$app/components/database/application';

export function didUpdateFieldSettings(database: Database, settings: FieldSettingsPB) {
  const { field_id: fieldId, visibility, width } = settings;
  const field = database.fields.find((field) => field.id === fieldId);

  if (!field) return;
  field.visibility = visibility;
  field.width = width;
}
