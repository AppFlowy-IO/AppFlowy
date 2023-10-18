import React, { useCallback, useEffect, useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { Article } from '@mui/icons-material';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { Page } from '$app_reducers/pages/slice';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { pageTypeMap } from '$app/constants';
import { LinearProgress } from '@mui/material';
import Tooltip from "@mui/material/Tooltip";

function PageInline({ pageId }: { pageId: string }) {
  const { t } = useTranslation();
  const page = useAppSelector((state) => state.pages.pageMap[pageId]);
  const navigate = useNavigate();
  const [currentPage, setCurrentPage] = useState<Page | null>(page);
  const loadPage = useCallback(async (id: string) => {
    const controller = new PageController(id);

    const page = await controller.getPage();
    setCurrentPage(page);
  }, []);

  const navigateToPage = useCallback(
    (page: Page) => {
      const pageType = pageTypeMap[page.layout];
      navigate(`/page/${pageType}/${page.id}`);
    },
    [navigate]
  );

  useEffect(() => {
    if (!page) {
      loadPage(pageId);
    } else {
      setCurrentPage(page);
    }

  }, [page, loadPage, pageId]);


  return currentPage ? (
    <Tooltip arrow title={t('document.mention.page.tooltip')} placement={'top'}>
      <span
        onClick={() => {
          if (!currentPage) return;

          navigateToPage(currentPage);
        }}
        className={'inline-block cursor-pointer rounded px-1 hover:bg-content-blue-100'}
      >
      <span className={'mr-1'}>{currentPage.icon?.value || <Article />}</span>
      <span className={'font-medium underline '}>{currentPage.name || t('menuAppHeader.defaultNewPageName')}</span>
    </span>
    </Tooltip>

  ) : (
    <span>
      <LinearProgress />
    </span>
  );
}

export default PageInline;
