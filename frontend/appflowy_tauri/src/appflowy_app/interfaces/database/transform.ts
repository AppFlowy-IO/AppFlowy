import { FieldPB } from '@/services/backend';
import type { Database } from './types';

export const fieldPbToField = (fieldPb: FieldPB): Database.Field => ({
  id: fieldPb.id,
  name: fieldPb.name,
  type: fieldPb.field_type,
  visibility: fieldPb.visibility,
  width: fieldPb.width,
  isPrimary: fieldPb.is_primary,
});
