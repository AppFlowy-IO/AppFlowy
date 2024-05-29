import { YDatabaseField } from '@/application/collab.type';
import { getTypeOptions } from '../type_option';
import { NumberFormat } from './number.type';

export function parseNumberTypeOptions(field: YDatabaseField) {
  const numberTypeOption = getTypeOptions(field)?.toJSON();

  return {
    format: parseInt(numberTypeOption.format) as NumberFormat,
  };
}
