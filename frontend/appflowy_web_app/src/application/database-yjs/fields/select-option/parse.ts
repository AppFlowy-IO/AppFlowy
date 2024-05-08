import { YDatabaseField, YjsDatabaseKey } from '@/application/collab.type';
import { getTypeOptions } from '../type_option';
import { SelectTypeOption } from './select_option.type';

export function parseSelectOptionTypeOptions(field: YDatabaseField) {
  const content = getTypeOptions(field)?.get(YjsDatabaseKey.content);

  if (!content) return null;

  try {
    return JSON.parse(content) as SelectTypeOption;
  } catch (e) {
    return null;
  }
}

export function parseSelectOptionCellData(field: YDatabaseField, data: string) {
  const typeOption = parseSelectOptionTypeOptions(field);
  const selectedIds = typeof data === 'string' ? data.split(',') : [];

  return selectedIds
    .map((id) => {
      const option = typeOption?.options?.find((option) => option.id === id);

      return option?.name ?? '';
    })
    .join(', ');
}
