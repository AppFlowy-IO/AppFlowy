import React, { memo, useCallback } from 'react';
import { Page, PageIcon } from '$app_reducers/pages/slice';
import ViewTitle from '$app/components/_shared/view_title/ViewTitle';
import { updatePageIcon } from '$app/application/folder/page.service';

interface DocumentHeaderProps {
  page: Page;
}

export function DocumentHeader({ page }: DocumentHeaderProps) {
  const pageId = page.id;

  const onUpdateIcon = useCallback(
    async (icon: PageIcon) => {
      await updatePageIcon(pageId, icon.value ? icon : undefined);
    },
    [pageId]
  );

  if (!page) return null;
  return (
    <div className={'document-header select-none px-16 pt-4'}>
      <ViewTitle showTitle={false} onUpdateIcon={onUpdateIcon} view={page} />
    </div>
  );
}

export default memo(DocumentHeader);
