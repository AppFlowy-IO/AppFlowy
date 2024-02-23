import React, { useCallback, useMemo } from 'react';
import { useLoadExpandedPages } from '$app/components/layout/bread_crumb/Breadcrumb.hooks';
import Breadcrumbs from '@mui/material/Breadcrumbs';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import { Page, pageTypeMap } from '$app_reducers/pages/slice';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { getPageIcon } from '$app/hooks/page.hooks';

function Breadcrumb() {
  const { t } = useTranslation();
  const { isTrash, pagePath, currentPage } = useLoadExpandedPages();
  const navigate = useNavigate();

  const parentPages = useMemo(() => pagePath.slice(1, -1).filter(Boolean) as Page[], [pagePath]);
  const navigateToPage = useCallback(
    (page: Page) => {
      const pageType = pageTypeMap[page.layout];

      navigate(`/page/${pageType}/${page.id}`);
    },
    [navigate]
  );

  if (!currentPage) {
    if (isTrash) {
      return <Typography className={'text-text-title'}>{t('trash.text')}</Typography>;
    }

    return null;
  }

  return (
    <Breadcrumbs aria-label='breadcrumb'>
      {parentPages?.map((page: Page) => (
        <Link
          key={page.id}
          className={'flex cursor-pointer select-none gap-1'}
          underline='hover'
          color='inherit'
          onClick={() => {
            navigateToPage(page);
          }}
        >
          <div>{getPageIcon(page)}</div>

          {page.name || t('document.title.placeholder')}
        </Link>
      ))}

      <div className={'flex select-none gap-1 text-text-title'}>
        <div className={'select-none'}>{getPageIcon(currentPage)}</div>
        {currentPage.name || t('menuAppHeader.defaultNewPageName')}
      </div>
    </Breadcrumbs>
  );
}

export default Breadcrumb;
