import { ReactComponent as DocumentSvg } from '$icons/16x/document.svg';
import { ReactComponent as GridSvg } from '$icons/16x/grid.svg';
import { ReactComponent as BoardSvg } from '$icons/16x/board.svg';
import { ReactComponent as CalendarSvg } from '$icons/16x/date.svg';
import { ViewLayout } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { useEditorContext } from '@/components/editor/EditorContext';
import { ViewMetaIcon } from '@/components/view-meta';
import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

function MentionPage({ pageId }: { pageId: string }) {
  const context = useEditorContext();
  const { navigateToView, loadViewMeta } = context;
  const [unPublished, setUnPublished] = useState(false);
  const [meta, setMeta] = useState<ViewMeta | null>(null);

  useEffect(() => {
    void (async () => {
      if (loadViewMeta) {
        setUnPublished(false);
        try {
          const meta = await loadViewMeta(pageId);

          setMeta(meta);
        } catch (e) {
          setUnPublished(true);
        }
      }
    })();
  }, [loadViewMeta, pageId]);

  const icon = useMemo(() => {
    if (meta?.icon) {
      try {
        return JSON.parse(meta.icon) as ViewMetaIcon;
      } catch (e) {
        return;
      }
    }

    return;
  }, [meta?.icon]);

  const defaultIcon = useMemo(() => {
    switch (meta?.layout) {
      case ViewLayout.Document:
        return <DocumentSvg />;
      case ViewLayout.Grid:
        return <GridSvg />;
      case ViewLayout.Board:
        return <BoardSvg />;
      case ViewLayout.Calendar:
        return <CalendarSvg />;
      default:
        return <DocumentSvg />;
    }
  }, [meta?.layout]);

  const { t } = useTranslation();

  return (
    <span
      onClick={() => {
        void navigateToView?.(pageId);
      }}
      className={`mention-inline px-1 underline`}
      contentEditable={false}
    >
      {unPublished ? (
        <span className={'mention-unpublished font-semibold text-text-caption'}>No Access</span>
      ) : (
        <>
          <span className={'mention-icon'}>{icon?.value || defaultIcon}</span>

          <span className={'mention-content'}>{meta?.name || t('menuAppHeader.defaultNewPageName')}</span>
        </>
      )}
    </span>
  );
}

export default MentionPage;
