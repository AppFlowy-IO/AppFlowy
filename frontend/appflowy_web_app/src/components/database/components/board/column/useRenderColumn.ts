import { YjsDatabaseKey } from '@/application/collab.type';
import { FieldType, parseSelectOptionTypeOptions, useFieldSelector } from '@/application/database-yjs';
import { SelectOptionColorMap } from '@/components/database/components/cell/cell.const';
import { useMemo } from 'react';

export function useRenderColumn(id: string, fieldId: string) {
  const { field } = useFieldSelector(fieldId);
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;
  const fieldName = field?.get(YjsDatabaseKey.name) || '';
  const header = useMemo(() => {
    if (!field) return null;
    switch (fieldType) {
      case FieldType.SingleSelect:
      case FieldType.MultiSelect: {
        const option = parseSelectOptionTypeOptions(field)?.options.find((option) => option.id === id);

        return {
          name: option?.name || `No ${fieldName}`,
          color: option?.color ? SelectOptionColorMap[option?.color] : 'transparent',
        };
      }

      default:
        return null;
    }
  }, [field, fieldName, fieldType, id]);

  return {
    header,
  };
}
