import React, { memo, useCallback, useEffect, useRef, useState } from 'react';
import { Page, PageCover, PageIcon } from '$app_reducers/pages/slice';
import ViewTitle from '$app/components/_shared/view_title/ViewTitle';
import { updatePageIcon } from '$app/application/folder/page.service';

interface DocumentHeaderProps {
  page: Page;
  onUpdateCover: (cover?: PageCover) => void;
}

export function DocumentHeader({ page, onUpdateCover }: DocumentHeaderProps) {
  const pageId = page.id;
  const ref = useRef<HTMLDivElement>(null);

  const [forceHover, setForceHover] = useState(false);
  const onUpdateIcon = useCallback(
    async (icon: PageIcon) => {
      await updatePageIcon(pageId, icon.value ? icon : undefined);
    },
    [pageId]
  );

  useEffect(() => {
    const parent = ref.current?.parentElement;

    if (!parent) return;

    const documentDom = parent.querySelector('.appflowy-editor') as HTMLElement;

    if (!documentDom) return;

    const handleMouseMove = (e: MouseEvent) => {
      const isMoveInTitle = Boolean(e.target instanceof HTMLElement && e.target.closest('.document-title'));
      const isMoveInHeader = Boolean(e.target instanceof HTMLElement && e.target.closest('.document-header'));

      setForceHover(isMoveInTitle || isMoveInHeader);
    };

    documentDom.addEventListener('mousemove', handleMouseMove);
    return () => {
      documentDom.removeEventListener('mousemove', handleMouseMove);
    };
  }, []);

  if (!page) return null;
  return (
    <div ref={ref} className={'document-header select-none'}>
      <ViewTitle
        showCover
        showTitle={false}
        forceHover={forceHover}
        onUpdateCover={onUpdateCover}
        onUpdateIcon={onUpdateIcon}
        view={page}
      />
    </div>
  );
}

export default memo(DocumentHeader);
