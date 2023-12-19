import React, { useCallback, useEffect, useState } from 'react';
import { Mention, MentionPage } from '$app/application/document/document.types';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { pageTypeMap } from '$app_reducers/pages/slice';

export function MentionLeaf({ children, mention }: { mention: Mention; children: React.ReactNode }) {
  const { t } = useTranslation();
  const [page, setPage] = useState<MentionPage | null>(null);
  const navigate = useNavigate();
  const loadPage = useCallback(async () => {
    if (!mention.page) return;
    const page = await new PageController(mention.page).getPage();

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
    <>
      {page && (
        <span className={'inline-flex cursor-pointer items-center'} onClick={openPage}>
          <span className={'mr-1 inline-flex items-center'}>{page.icon?.value || <DocumentSvg />}</span>
          <span className={'text-sx underline'}>{page.name || t('document.title.placeholder')}</span>
        </span>
      )}
      <span className={'absolute left-0 right-0 h-0 w-0 opacity-0'}>{children}</span>
    </>
  );
}

export default MentionLeaf;
