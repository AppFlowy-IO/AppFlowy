import React, { useCallback, useMemo } from 'react';
import { useLoadExpandedPages } from '$app/components/layout/Breadcrumb/Breadcrumb.hooks';
import Breadcrumbs from '@mui/material/Breadcrumbs';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import { Page, pageTypeMap } from '$app_reducers/pages/slice';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

function Breadcrumb() {
  const { t } = useTranslation();
  const { pagePath, currentPage } = useLoadExpandedPages();
  const navigate = useNavigate();

  const parentPages = useMemo(() => pagePath.slice(1, -1).filter(Boolean) as Page[], [pagePath]);
  const navigateToPage = useCallback(
    (page: Page) => {
      const pageType = pageTypeMap[page.layout];

      navigate(`/page/${pageType}/${page.id}`);
    },
    [navigate]
  );

  return (
    <Breadcrumbs aria-label='breadcrumb'>
      {parentPages?.map((page: Page) => (
        <Link
          key={page.id}
          underline='hover'
          color='inherit'
          onClick={() => {
            navigateToPage(page);
          }}
        >
          {page.name || t('document.title.placeholder')}
        </Link>
      ))}
      <Typography color='text.primary'>{currentPage?.name || t('menuAppHeader.defaultNewPageName')}</Typography>
    </Breadcrumbs>
  );
}

export default Breadcrumb;
