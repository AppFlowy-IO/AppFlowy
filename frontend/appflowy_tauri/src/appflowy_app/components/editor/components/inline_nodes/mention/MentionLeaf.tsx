import React, { useCallback, useEffect, useState } from 'react';
import { Mention, MentionPage } from '$app/application/document/document.types';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { pageTypeMap } from '$app_reducers/pages/slice';
import { getPage } from '$app/application/folder/page.service';

export function MentionLeaf({ children, mention }: { mention: Mention; children: React.ReactNode }) {
  const { t } = useTranslation();
  const [page, setPage] = useState<MentionPage | null>(null);
  const navigate = useNavigate();
  const loadPage = useCallback(async () => {
    if (!mention.page) return;
    const page = await getPage(mention.page);

    setPage(page);
  }, [mention.page]);

  useEffect(() => {
    void loadPage();
  }, [loadPage]);

  const openPage = useCallback(() => {
    if (!page) return;
    const pageType = pageTypeMap[page.layout];

    navigate(`/page/${pageType}/${page.id}`);
  }, [navigate, page]);

  return (
    <span className={'relative'}>
      {page && (
        <span
          className={'relative inline-flex cursor-pointer items-center hover:bg-content-blue-100'}
          onClick={openPage}
        >
          <span className={'text-sx absolute left-0'}>{page.icon?.value || <DocumentSvg />}</span>
          <span className={'ml-6 underline'}>{page.name || t('document.title.placeholder')}</span>
        </span>
      )}
      <span className={'invisible'}>{children}</span>
    </span>
  );
}

export default MentionLeaf;
