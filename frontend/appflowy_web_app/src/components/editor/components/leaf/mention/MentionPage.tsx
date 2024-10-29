import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { traverseBlock } from '@/application/slate-yjs/utils/convert';
import { MentionType, View, ViewLayout, YjsEditorKey, YSharedRoot } from '@/application/types';
import { ReactComponent as NorthEast } from '@/assets/north_east.svg';
import { ReactComponent as MarkIcon } from '@/assets/paragraph_mark.svg';

import { ViewIcon } from '@/components/_shared/view-icon';
import { useEditorContext } from '@/components/editor/EditorContext';
import { isFlagEmoji } from '@/utils/emoji';
import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';

function MentionPage ({ pageId, blockId, type }: { pageId: string; blockId?: string; type?: MentionType }) {
  const context = useEditorContext();
  const editor = useSlateStatic();
  const currentViewId = context.viewId;
  const { navigateToView, loadViewMeta, loadView } = context;
  const [noAccess, setNoAccess] = useState(false);
  const [meta, setMeta] = useState<View | null>(null);
  const [content, setContent] = useState<string>('');

  useEffect(() => {
    void (async () => {
      if (loadViewMeta) {
        setNoAccess(false);
        try {
          const meta = await loadViewMeta(pageId, setMeta);

          setMeta(meta);
        } catch (e) {
          setNoAccess(true);
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

  useEffect(() => {
    void (
      async () => {
        const pageName = meta?.name || t('menuAppHeader.defaultNewPageName');

        if (blockId) {
          if (currentViewId === pageId) {
            const entry = CustomEditor.getBlockEntry(editor as YjsEditor, blockId);

            if (entry) {
              const [node] = entry;

              setContent(CustomEditor.getBlockTextContent(node, 2));
              return;
            }

          } else {
            try {
              const otherDoc = await loadView?.(pageId);

              if (!otherDoc) return;

              const sharedRoot = otherDoc.getMap(YjsEditorKey.data_section) as YSharedRoot;

              const node = traverseBlock(blockId, sharedRoot);

              if (!node) return;

              setContent(`${pageName} - ${CustomEditor.getBlockTextContent(node, 2)}`);
              return;

            } catch (e) {
              // do nothing
            }
          }

        }

        setContent(pageName);
      }
    )();
  }, [blockId, currentViewId, editor, loadView, meta?.name, pageId, t]);

  const mentionIcon = useMemo(() => {
    if (pageId === currentViewId && blockId) {
      return <MarkIcon className={'text-icon-secondary ml-0.5'} />;
    }

    return <>
      {icon?.value || <ViewIcon
        layout={meta?.layout || ViewLayout.Document}
        size={'unset'}
        className={'text-text-title ml-0.5'}
      />}
      {type === MentionType.PageRef &&
        <span className={`absolute ${icon?.value ? 'right-1 bottom-1' : 'right-0 bottom-0'}`}>
          <NorthEast className={'w-3 h-3 text-content-blue-700'} />
        </span>
      }
    </>;
  }, [blockId, currentViewId, icon?.value, meta?.layout, pageId, type]);

  return (
    <span
      onClick={(e) => {
        e.stopPropagation();
        void navigateToView?.(pageId, blockId);
      }}
      className={`mention-inline cursor-pointer pr-1 underline`}
      contentEditable={false}
      data-mention-id={pageId}
    >
      {noAccess ? (
        <span className={'mention-unpublished font-semibold text-text-caption'}>No Access</span>
      ) : (
        <>
          <span className={`mention-icon ${isFlag ? 'icon' : ''}`}>
            {mentionIcon}
          </span>

          <span className={'mention-content opacity-80 hover:opacity-100'}>
            {content}
          </span>
        </>
      )}
    </span>
  );
}

export default MentionPage;
