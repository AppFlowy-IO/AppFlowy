import { useDatabaseContext } from '@/application/database-yjs';
import { FieldId } from '@/application/types';
import { FieldVisibility } from '@/application/database-yjs/database.type';
import { useFieldsSelector } from '@/application/database-yjs/selector';
import { useCallback, useMemo } from 'react';
import { getPlatform } from '@/utils/platform';

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
  const context = useDatabaseContext();
  const isDocumentBlock = context.isDocumentBlock;
  const viewId = context.viewId;
  const scrollLeft = context.scrollLeft;
  const isMobile = getPlatform().isMobile;
  const renderColumns = useMemo(() => {
    const data = fields.map((column) => ({
      ...column,
      type: GridColumnType.Field,
    }));

    return [
      {
        type: GridColumnType.Action,
        width: isMobile ? 16 : (scrollLeft === undefined ? 96 : scrollLeft),
      },
      ...data,
      {
        type: GridColumnType.NewProperty,
        width: 150,
      },
      // {
      //   type: GridColumnType.Action,
      //   width: 64,
      // },
    ].filter(Boolean) as RenderColumn[];
  }, [isMobile, fields, scrollLeft]);

  const columnWidth = useCallback(
    (index: number, containerWidth: number) => {
      const { type, width } = renderColumns[index];

      if (type === GridColumnType.NewProperty) {
        const totalWidth = renderColumns.reduce((acc, column) => acc + column.width, 0);
        const tabWidth = document.querySelector(`.grid-table-${viewId}`)?.closest('.appflowy-database')?.querySelector('.database-tabs')?.clientWidth || 0;
        const documentWidth = tabWidth + (scrollLeft || 0);
        const remainingWidth = (isDocumentBlock ? documentWidth : tabWidth + 96) - totalWidth;

        return remainingWidth > 0 ? remainingWidth + width : width;
      }

      if (index > 0 && type === GridColumnType.Action && containerWidth < 800) {
        return 16;
      }

      return width;
    },
    [isDocumentBlock, renderColumns, scrollLeft, viewId],
  );

  return {
    fields: renderColumns,
    columnWidth,
  };
}
