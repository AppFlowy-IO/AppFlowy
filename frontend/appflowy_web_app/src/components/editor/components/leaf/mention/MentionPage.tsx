import { ViewLayout, View } from '@/application/types';
import { ViewIcon } from '@/components/_shared/view-icon';
import { useEditorContext } from '@/components/editor/EditorContext';
import { isFlagEmoji } from '@/utils/emoji';
import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

function MentionPage ({ pageId }: { pageId: string }) {
  const context = useEditorContext();
  const { navigateToView, loadViewMeta } = context;
  const [unPublished, setUnPublished] = useState(false);
  const [meta, setMeta] = useState<View | null>(null);

  useEffect(() => {
    void (async () => {
      if (loadViewMeta) {
        setUnPublished(false);
        try {
          const meta = await loadViewMeta(pageId, setMeta);

          setMeta(meta);
        } catch (e) {
          setUnPublished(true);
        }
      }
    })();
  }, [loadViewMeta, pageId]);

  const icon = useMemo(() => {
    return meta?.icon;
  }, [meta?.icon]);

  const { t } = useTranslation();

  const isFlag = useMemo(() => {
    return icon ? isFlagEmoji(icon.value) : false;
  }, [icon]);

  return (
    <span
      onClick={() => {
        void navigateToView?.(pageId);
      }}
      className={`mention-inline px-1 underline`}
      contentEditable={false}
      data-mention-id={pageId}
    >
      {unPublished ? (
        <span className={'mention-unpublished font-semibold text-text-caption'}>No Access</span>
      ) : (
        <>
          <span className={`mention-icon ${isFlag ? 'icon' : ''}`}>
            {icon?.value || <ViewIcon layout={meta?.layout || ViewLayout.Document} size={'small'} />}
          </span>

          <span className={'mention-content'}>{meta?.name || t('menuAppHeader.defaultNewPageName')}</span>
        </>
      )}
    </span>
  );
}

export default MentionPage;
