import React, { useCallback, useMemo } from 'react';
import { useLoadExpandedPages } from '$app/components/layout/Breadcrumb/Breadcrumb.hooks';
import Breadcrumbs from '@mui/material/Breadcrumbs';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import { Page } from '$app_reducers/pages/slice';
import { useNavigate } from 'react-router-dom';
import { pageTypeMap } from '$app/constants';
import { useTranslation } from 'react-i18next';

function Breadcrumb() {
  const { t } = useTranslation();
  const { pagePath } = useLoadExpandedPages();
  const navigate = useNavigate();
  const activePage = useMemo(() => pagePath[pagePath.length - 1], [pagePath]);
  const parentPages = useMemo(() => pagePath.slice(0, pagePath.length - 1) as Page[], [pagePath]);
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
          {page.name}
        </Link>
      ))}
      <Typography color='text.primary'>{activePage?.name || t('menuAppHeader.defaultNewPageName')}</Typography>
    </Breadcrumbs>
  );
}

export default Breadcrumb;
