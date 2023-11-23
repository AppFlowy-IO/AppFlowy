import React, { useCallback } from 'react';
import { Page, PageIcon } from '$app_reducers/pages/slice';
import ViewTitle from '$app/components/_shared/ViewTitle';
import { ViewIconTypePB } from '@/services/backend';
import { useViewId } from '$app/hooks';
import { updateRowMeta } from '$app/components/database/application/row/row_service';
import { cellService, TextCell } from '$app/components/database/application';

interface Props {
  page: Page | null;
  icon?: string;
  cell: TextCell;
}

function RecordTitle({ cell, page, icon }: Props) {
  const { data: title, fieldId, rowId } = cell;
  const viewId = useViewId();

  const onTitleChange = useCallback(
    async (title: string) => {
      try {
        await cellService.updateCell(viewId, rowId, fieldId, title);
      } catch (e) {
        // toast.error('Failed to update title');
      }
    },
    [fieldId, rowId, viewId]
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
            icon: icon
              ? {
                  ty: ViewIconTypePB.Emoji,
                  value: icon,
                }
              : undefined,
          }}
        />
      )}
    </div>
  );
}

export default React.memo(RecordTitle);
