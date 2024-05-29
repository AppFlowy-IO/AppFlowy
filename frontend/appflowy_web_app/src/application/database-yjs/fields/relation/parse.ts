import { YDatabaseField } from '@/application/collab.type';
import { RelationTypeOption } from './relation.type';
import { getTypeOptions } from '../type_option';

export function parseRelationTypeOption(field: YDatabaseField) {
  const relationTypeOption = getTypeOptions(field)?.toJSON();

  return relationTypeOption as RelationTypeOption;
}
