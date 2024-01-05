import React, { memo, useCallback } from 'react';
import { Page, PageIcon } from '$app_reducers/pages/slice';
import { useAppDispatch } from '$app/stores/store';
import ViewTitle from '$app/components/_shared/ViewTitle';
import { updatePageIcon } from '$app_reducers/pages/async_actions';

interface DocumentHeaderProps {
  page: Page;
}

export function DocumentHeader({ page }: DocumentHeaderProps) {
  const dispatch = useAppDispatch();

  const pageId = page.id;
  const onUpdateIcon = useCallback(
    (icon: PageIcon) => {
      void dispatch(
        updatePageIcon({
          id: pageId,
          icon: icon.value ? icon : undefined,
        })
      );
    },
    [dispatch, pageId]
  );

  if (!page) return null;
  return (
    <div className={'document-header px-16 py-4'}>
      <ViewTitle showTitle={false} onUpdateIcon={onUpdateIcon} view={page} />
    </div>
  );
}

export default memo(DocumentHeader);
