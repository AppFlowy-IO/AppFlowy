import React, { useCallback } from 'react';
import { useLoadExpandedPages } from '$app/components/layout/bread_crumb/Breadcrumb.hooks';
import Breadcrumbs from '@mui/material/Breadcrumbs';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import { Page } from '$app_reducers/pages/slice';
import { useTranslation } from 'react-i18next';
import { getPageIcon } from '$app/hooks/page.hooks';
import { useAppDispatch } from '$app/stores/store';
import { openPage } from '$app_reducers/pages/async_actions';

function Breadcrumb() {
  const { t } = useTranslation();
  const { isTrash, pagePath, currentPage } = useLoadExpandedPages();
  const dispatch = useAppDispatch();

  const navigateToPage = useCallback(
    (page: Page) => {
      void dispatch(openPage(page.id));
    },
    [dispatch]
  );

  if (!currentPage) {
    if (isTrash) {
      return <Typography className={'text-text-title'}>{t('trash.text')}</Typography>;
    }

    return null;
  }

  return (
    <Breadcrumbs aria-label='breadcrumb'>
      {pagePath?.map((page: Page, index) => {
        if (index === pagePath.length - 1) {
          return (
            <div key={page.id} className={'flex cursor-default select-none gap-1 text-text-title'}>
              <div>{getPageIcon(page)}</div>
              {page.name.trim() || t('menuAppHeader.defaultNewPageName')}
            </div>
          );
        }

        return (
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

            {page.name.trim() || t('menuAppHeader.defaultNewPageName')}
          </Link>
        );
      })}
    </Breadcrumbs>
  );
}

export default Breadcrumb;
