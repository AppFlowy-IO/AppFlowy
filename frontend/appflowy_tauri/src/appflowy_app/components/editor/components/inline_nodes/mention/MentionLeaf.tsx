import React, { useCallback, useEffect, useState } from 'react';
import { Mention, MentionPage } from '$app/application/document/document.types';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { pageTypeMap } from '$app_reducers/pages/slice';
import { getPage } from '$app/application/folder/page.service';
import { useSelected } from 'slate-react';
import { ReactComponent as EyeClose } from '$app/assets/eye_close.svg';
import { notify } from 'src/appflowy_app/components/_shared/notify';
import { subscribeNotifications } from '$app/application/notification';
import { FolderNotification } from '@/services/backend';

export function MentionLeaf({ children, mention }: { mention: Mention; children: React.ReactNode }) {
  const { t } = useTranslation();
  const [page, setPage] = useState<MentionPage | null>(null);
  const [error, setError] = useState<boolean>(false);
  const navigate = useNavigate();
  const selected = useSelected();
  const loadPage = useCallback(async () => {
    setError(true);
    if (!mention.page) return;
    try {
      const page = await getPage(mention.page);

      setPage(page);
      setError(false);
    } catch {
      setPage(null);
      setError(true);
    }
  }, [mention.page]);

  useEffect(() => {
    void loadPage();
  }, [loadPage]);

  const openPage = useCallback(() => {
    if (!page) {
      notify.error(t('document.mention.deletedContent'));
      return;
    }

    const pageType = pageTypeMap[page.layout];

    navigate(`/page/${pageType}/${page.id}`);
  }, [navigate, page, t]);

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
    <span className={'relative'}>
      <span
        className={'relative mx-1 inline-flex cursor-pointer items-center hover:rounded hover:bg-content-blue-100'}
        onClick={openPage}
        style={{
          backgroundColor: selected ? 'var(--content-blue-100)' : undefined,
        }}
      >
        {page && (
          <>
            <span className={'text-sx absolute left-0.5'}>{page.icon?.value || <DocumentSvg />}</span>
            <span className={'ml-6 mr-0.5 underline'}>{page.name || t('document.title.placeholder')}</span>
          </>
        )}
        {error && (
          <>
            <span className={'text-sx absolute left-0.5'}>
              <EyeClose />
            </span>
            <span className={'ml-6 mr-0.5 text-text-caption underline'}>{t('document.mention.deleted')}</span>
          </>
        )}
      </span>

      <span className={'invisible'}>{children}</span>
    </span>
  );
}

export default MentionLeaf;
