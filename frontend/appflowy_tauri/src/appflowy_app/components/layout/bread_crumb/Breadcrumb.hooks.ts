import { useAppSelector } from '$app/stores/store';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { useParams, useLocation } from 'react-router-dom';
import { Page } from '$app_reducers/pages/slice';
import { getPage } from '$app/application/folder/page.service';

export function useLoadExpandedPages() {
  const params = useParams();
  const location = useLocation();
  const isTrash = useMemo(() => location.pathname.includes('trash'), [location.pathname]);
  const currentPageId = params.id;
  const pageMap = useAppSelector((state) => state.pages.pageMap);
  const currentPage = currentPageId ? pageMap[currentPageId] : null;

  const [pagePath, setPagePath] = useState<
    (
      | Page
      | {
          name: string;
        }
    )[]
  >([]);

  const loadPagePath = useCallback(
    async (pageId: string) => {
      let page = pageMap[pageId];

      if (!page) {
        try {
          page = await getPage(pageId);
        } catch (e) {
          // do nothing
        }

        if (!page) {
          return;
        }
      }

      setPagePath((prev) => {
        return [page, ...prev];
      });

      if (page.parentId) {
        await loadPagePath(page.parentId);
      }
    },
    [pageMap]
  );

  useEffect(() => {
    setPagePath([]);
    if (!currentPageId) {
      return;
    }

    void loadPagePath(currentPageId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPageId]);

  useEffect(() => {
    setPagePath((prev) => {
      return prev.map((page, index) => {
        if (!page) return page;
        if (index === 0) return page;
        return 'id' in page && page.id ? pageMap[page.id] : page;
      });
    });
  }, [pageMap]);

  return {
    pagePath,
    currentPage,
    isTrash,
  };
}
