import React, { useCallback } from 'react';
import { PageIcon } from '$app_reducers/pages/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import ViewTitle from '$app/components/_shared/ViewTitle';
import { updatePageIcon, updatePageName } from '$app_reducers/pages/async_actions';

interface DocumentHeaderProps {
  pageId: string;
  onSplitTitle: (splitText: string) => void;
}

export function DocumentHeader({ pageId, onSplitTitle }: DocumentHeaderProps) {
  const page = useAppSelector((state) => state.pages.pageMap[pageId]);
  const dispatch = useAppDispatch();
  const onTitleChange = useCallback(
    (newTitle: string) => {
      void dispatch(
        updatePageName({
          id: pageId,
          name: newTitle,
        })
      );
    },
    [dispatch, pageId]
  );

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
      <ViewTitle onSplitTitle={onSplitTitle} onUpdateIcon={onUpdateIcon} onTitleChange={onTitleChange} view={page} />
    </div>
  );
}

export default DocumentHeader;
