import { useAppSelector } from "$app/stores/store";
import { useCallback, useEffect, useMemo, useState } from 'react';
import { useParams, useLocation } from 'react-router-dom';
import { Page } from '$app_reducers/pages/slice';
import { useTranslation } from 'react-i18next';
import { PageController } from "$app/stores/effects/workspace/page/page_controller";

export function useLoadExpandedPages() {
  const { t } = useTranslation();
  const params = useParams();
  const location = useLocation();
  const isTrash = useMemo(() => location.pathname.includes('trash'), [location.pathname]);
  const currentPageId = params.id;
  const pageMap = useAppSelector((state) => state.pages.pageMap);
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
      const controller = new PageController(pageId);
      if (!page) {
        try {
          page = await controller.getPage();
        } catch (e) {
          // do nothing
        }

        if (!page) {
          return;
        }
      }
      setPagePath(prev => {
        return [
          page,
          ...prev
        ]
      });
      await loadPagePath(page.parentId);

    }, [pageMap]);

  useEffect(() => {
    setPagePath([]);
    if (!currentPageId) {
      return;
    }
    loadPagePath(currentPageId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPageId]);

  useEffect(() => {
    if (isTrash) {
      setPagePath([
        {
          name: t('trash.text'),
        },
      ]);
    }
  }, [isTrash, t]);

  return {
    pagePath,
  };
}
