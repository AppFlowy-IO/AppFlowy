import { FieldId } from '@/application/collab.type';
import { FieldVisibility } from '@/application/database-yjs/database.type';
import { useFieldsSelector } from '@/application/database-yjs/selector';
import { useCallback, useMemo } from 'react';

export enum GridColumnType {
  Action,
  Field,
  NewProperty,
}

export type RenderColumn = {
  type: GridColumnType;
  visibility?: FieldVisibility;
  fieldId?: FieldId;
  width: number;
  wrap?: boolean;
};

export function useRenderFields() {
  const fields = useFieldsSelector();

  const renderColumns = useMemo(() => {
    const data = fields.map((column) => ({
      ...column,
      type: GridColumnType.Field,
    }));

    return [
      {
        type: GridColumnType.Action,
        width: 64,
      },
      ...data,
      {
        type: GridColumnType.NewProperty,
        width: 150,
      },
      {
        type: GridColumnType.Action,
        width: 64,
      },
    ].filter(Boolean) as RenderColumn[];
  }, [fields]);

  const columnWidth = useCallback(
    (index: number, containerWidth: number) => {
      const { type, width } = renderColumns[index];

      if (type === GridColumnType.NewProperty) {
        const totalWidth = renderColumns.reduce((acc, column) => acc + column.width, 0);
        const remainingWidth = containerWidth - totalWidth;

        return remainingWidth > 0 ? remainingWidth + width : width;
      }

      if (type === GridColumnType.Action && containerWidth < 800) {
        return 16;
      }

      return width;
    },
    [renderColumns]
  );

  return {
    fields: renderColumns,
    columnWidth,
  };
}
