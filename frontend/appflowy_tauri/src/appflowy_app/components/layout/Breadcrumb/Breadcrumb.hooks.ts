import { useAppDispatch } from '$app/stores/store';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { useParams, useLocation } from 'react-router-dom';
import { Page, pagesActions } from '$app_reducers/pages/slice';
import { Log } from '$app/utils/log';
import { useTranslation } from 'react-i18next';

export function useLoadExpandedPages() {
  const dispatch = useAppDispatch();
  const { t } = useTranslation();
  const params = useParams();
  const location = useLocation();
  const isTrash = useMemo(() => location.pathname.includes('trash'), [location.pathname]);
  const currentPageId = params.id;
  const [pagePath, setPagePath] = useState<
    (
      | Page
      | {
          name: string;
        }
    )[]
  >([]);

  const loadPage = useCallback(
    async (id: string) => {
      if (!id) return;
      const controller = new PageController(id);

      try {
        const page = await controller.getPage();
        const childPages = await controller.getChildPages();

        dispatch(pagesActions.addChildPages({ id, childPages }));
        dispatch(pagesActions.expandPage(id));

        setPagePath((prev) => [page, ...prev]);
        await loadPage(page.parentId);
      } catch (e) {
        Log.info(`${id} is workspace`);
      }
    },
    [dispatch]
  );

  useEffect(() => {
    setPagePath([]);
    if (!currentPageId) {
      return;
    }

    void (async () => {
      await loadPage(currentPageId);
    })();
  }, [currentPageId, dispatch, loadPage]);

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
