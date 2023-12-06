import React, { useCallback, useMemo } from 'react';
import { Page, PageIcon } from '$app_reducers/pages/slice';
import ViewTitle from '$app/components/_shared/ViewTitle';
import { ViewIconTypePB } from '@/services/backend';
import { useViewId } from '$app/hooks';
import { updateRowMeta } from '$app/components/database/application/row/row_service';
import { cellService, Field, RowMeta, TextCell } from '$app/components/database/application';
import { useDatabase } from '$app/components/database';
import { useCell } from '$app/components/database/components/cell/Cell.hooks';

interface Props {
  page: Page | null;
  row: RowMeta;
}

function RecordTitle({ row, page }: Props) {
  const { fields } = useDatabase();
  const field = useMemo(() => {
    return fields.find((field) => field.isPrimary) as Field;
  }, [fields]);
  const rowId = row.id;
  const cell = useCell(rowId, field) as TextCell;
  const title = cell.data;

  const viewId = useViewId();

  const onTitleChange = useCallback(
    async (title: string) => {
      try {
        await cellService.updateCell(viewId, rowId, field.id, title);
      } catch (e) {
        // toast.error('Failed to update title');
      }
    },
    [field.id, rowId, viewId]
  );

  const onUpdateIcon = useCallback(
    async (icon: PageIcon) => {
      try {
        await updateRowMeta(viewId, rowId, { iconUrl: icon.value });
      } catch (e) {
        // toast.error('Failed to update icon');
      }
    },
    [rowId, viewId]
  );

  return (
    <div className={'px-1 pb-4 pt-2'}>
      {page && (
        <ViewTitle
          onUpdateIcon={onUpdateIcon}
          onTitleChange={onTitleChange}
          view={{
            ...page,
            name: title,
            icon: row.icon
              ? {
                  ty: ViewIconTypePB.Emoji,
                  value: row.icon,
                }
              : undefined,
          }}
        />
      )}
    </div>
  );
}

export default React.memo(RecordTitle);
