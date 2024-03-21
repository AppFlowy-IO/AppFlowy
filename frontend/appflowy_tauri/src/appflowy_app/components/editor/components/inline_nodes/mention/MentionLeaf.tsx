import React, { useCallback, useEffect, useState } from 'react';
import { Mention, MentionPage } from '$app/application/document/document.types';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
import { useTranslation } from 'react-i18next';
import { getPage } from '$app/application/folder/page.service';
import { useSelected, useSlate } from 'slate-react';
import { ReactComponent as EyeClose } from '$app/assets/eye_close.svg';
import { notify } from 'src/appflowy_app/components/_shared/notify';
import { subscribeNotifications } from '$app/application/notification';
import { FolderNotification } from '@/services/backend';
import { Editor, Range } from 'slate';
import { useAppDispatch } from '$app/stores/store';
import { openPage } from '$app_reducers/pages/async_actions';

export function MentionLeaf({ mention }: { mention: Mention }) {
  const { t } = useTranslation();
  const [page, setPage] = useState<MentionPage | null>(null);
  const [error, setError] = useState<boolean>(false);
  const editor = useSlate();
  const selected = useSelected();
  const isCollapsed = editor.selection && Range.isCollapsed(editor.selection);
  const dispatch = useAppDispatch();

  useEffect(() => {
    if (selected && isCollapsed && page) {
      const afterPoint = editor.selection ? editor.after(editor.selection) : undefined;

      const afterStart = afterPoint ? Editor.start(editor, afterPoint) : undefined;

      if (afterStart) {
        editor.select(afterStart);
      }
    }
  }, [editor, isCollapsed, selected, page]);

  const loadPage = useCallback(async () => {
    setError(true);
    // keep old field for backward compatibility
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-expect-error
    const pageId = mention.page_id ?? mention.page;

    if (!pageId) return;
    try {
      const page = await getPage(pageId);

      setPage(page);
      setError(false);
    } catch {
      setPage(null);
      setError(true);
    }
  }, [mention]);

  useEffect(() => {
    void loadPage();
  }, [loadPage]);

  const handleOpenPage = useCallback(() => {
    if (!page) {
      notify.error(t('document.mention.deletedContent'));
      return;
    }

    void dispatch(openPage(page.id));
  }, [page, dispatch, t]);

  useEffect(() => {
    if (!page) return;
    const unsubscribePromise = subscribeNotifications(
      {
        [FolderNotification.DidUpdateView]: (changeset) => {
          setPage((prev) => {
            if (!prev) {
              return prev;
            }

            return {
              ...prev,
              name: changeset.name,
            };
          });
        },
      },
      {
        id: page.id,
      }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [page]);

  useEffect(() => {
    const parentId = page?.parentId;

    if (!parentId) return;

    const unsubscribePromise = subscribeNotifications(
      {
        [FolderNotification.DidUpdateChildViews]: (changeset) => {
          if (changeset.delete_child_views.includes(page.id)) {
            setPage(null);
            setError(true);
          }
        },
      },
      {
        id: parentId,
      }
    );

    return () => void unsubscribePromise.then((unsubscribe) => unsubscribe());
  }, [page]);

  return (
    <span
      className={`mention-inline mx-1 inline-flex select-none items-center gap-1`}
      onClick={handleOpenPage}
      contentEditable={false}
      style={{
        backgroundColor: selected ? 'var(--content-blue-100)' : undefined,
      }}
    >
      {error ? (
        <>
          <EyeClose />
          <span className={'mr-0.5 text-text-caption underline'}>{t('document.mention.deleted')}</span>
        </>
      ) : (
        page && (
          <>
            {page.icon?.value || <DocumentSvg />}
            <span className={'mr-1 underline'}>{page.name.trim() || t('menuAppHeader.defaultNewPageName')}</span>
          </>
        )
      )}
    </span>
  );
}

export default MentionLeaf;
