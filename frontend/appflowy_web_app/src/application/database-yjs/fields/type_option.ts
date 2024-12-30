import { YDatabaseField, YjsDatabaseKey } from '@/application/types';
import { FieldType } from '@/application/database-yjs';

export function getTypeOptions(field: YDatabaseField) {
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;

  return field?.get(YjsDatabaseKey.type_option)?.get(String(fieldType));
}
