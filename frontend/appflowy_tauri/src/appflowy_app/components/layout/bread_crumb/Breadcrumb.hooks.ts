import { useAppSelector } from '$app/stores/store';
import { useMemo } from 'react';
import { useParams, useLocation } from 'react-router-dom';
import { Page } from '$app_reducers/pages/slice';

export function useLoadExpandedPages() {
  const params = useParams();
  const location = useLocation();
  const isTrash = useMemo(() => location.pathname.includes('trash'), [location.pathname]);
  const currentPageId = params.id;
  const currentPage = useAppSelector((state) => (currentPageId ? state.pages.pageMap[currentPageId] : undefined));

  const pagePath = useAppSelector((state) => {
    const result: Page[] = [];

    if (!currentPage) return result;

    const findParent = (page: Page) => {
      if (!page.parentId) return;
      const parent = state.pages.pageMap[page.parentId];

      if (parent) {
        result.unshift(parent);
        findParent(parent);
      }
    };

    findParent(currentPage);
    result.push(currentPage);
    return result;
  });

  return {
    pagePath,
    currentPage,
    isTrash,
  };
}
