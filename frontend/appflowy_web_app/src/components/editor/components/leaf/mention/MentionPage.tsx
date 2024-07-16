import { ViewLayout } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { ViewIcon } from '@/components/_shared/view-icon';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

function MentionPage({ pageId }: { pageId: string }) {
  const context = useEditorContext();
  const { navigateToView, loadViewMeta, loadView } = context;
  const [unPublished, setUnPublished] = useState(false);
  const [meta, setMeta] = useState<ViewMeta | null>(null);

  useEffect(() => {
    void (async () => {
      if (loadViewMeta && loadView) {
        setUnPublished(false);
        try {
          await loadView(pageId);
          const meta = await loadViewMeta(pageId);

          setMeta(meta);
        } catch (e) {
          setUnPublished(true);
        }
      }
    })();
  }, [loadViewMeta, pageId, loadView]);

  const icon = useMemo(() => {
    return meta?.icon;
  }, [meta?.icon]);

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
        <span className={'mention-unpublished cursor-text font-semibold text-text-caption'}>No Access</span>
      ) : (
        <>
          <span className={'mention-icon icon'}>
            {icon?.value || <ViewIcon layout={meta?.layout || ViewLayout.Document} size={'small'} />}
          </span>

          <span className={'mention-content'}>{meta?.name || t('menuAppHeader.defaultNewPageName')}</span>
        </>
      )}
    </span>
  );
}

export default MentionPage;
