import { FieldId } from '@/application/collab.type';
import { FieldVisibility } from '@/application/database-yjs/database.type';
import { useGridColumnsSelector } from '@/application/database-yjs/selector';
import { useCallback, useMemo } from 'react';

export enum GridColumnType {
  Action,
  Field,
  NewProperty,
}

const defaultVisibilitys = [FieldVisibility.AlwaysShown, FieldVisibility.HideWhenEmpty];

export type RenderColumn = {
  type: GridColumnType;
  visibility?: FieldVisibility;
  fieldId?: FieldId;
  width: number;
  wrap?: boolean;
};

export function useRenderColumns(viewId: string) {
  const columns = useGridColumnsSelector(viewId, defaultVisibilitys);

  console.log('columns', columns);
  const renderColumns = useMemo(() => {
    const fields = columns.map((column) => ({
      ...column,
      type: GridColumnType.Field,
    }));

    return [
      {
        type: GridColumnType.Action,
        width: 96,
      },
      ...fields,
      {
        type: GridColumnType.NewProperty,
        width: 150,
      },
      {
        type: GridColumnType.Action,
        width: 96,
      },
    ].filter(Boolean) as RenderColumn[];
  }, [columns]);

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
    columns: renderColumns,
    columnWidth,
  };
}
