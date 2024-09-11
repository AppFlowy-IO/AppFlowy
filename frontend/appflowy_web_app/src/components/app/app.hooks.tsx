import { invalidToken } from '@/application/session/token';
import { GetViewRowsMap, LoadView, LoadViewMeta, View } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { AFConfigContext, useCurrentUser, useService } from '@/components/main/app.hooks';
import { findView } from '@/components/publish/header/utils';
import { uniqBy } from 'lodash-es';
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';

export interface AppContextType {
  toView: (viewId: string) => Promise<void>;
  loadViewMeta: LoadViewMeta;
  getViewRowsMap?: GetViewRowsMap;
  loadView: LoadView;
  outline?: View[];
  viewId?: string;
  currentWorkspaceId?: string;
  loadFavoriteViews?: () => Promise<void>;
  loadRecentViews?: () => Promise<void>;
  favoriteViews?: View[];
  recentViews?: View[];
}

export const AppContext = createContext<AppContextType | null>(null);

export const AppProvider = ({ children }: { children: React.ReactNode }) => {
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated;
  const currentUser = useCurrentUser();
  const params = useParams();
  const pathname = window.location.pathname;
  const viewId = params.viewId as string;
  const currentWorkspaceId = useMemo(() => params.workspaceId || currentUser?.latestWorkspaceId, [params.workspaceId, currentUser]);

  const [outline, setOutline] = useState<View[]>();
  const [favoriteViews, setFavoriteViews] = useState<View[]>();
  const [recentViews, setRecentViews] = useState<View[]>();

  const service = useService();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isAuthenticated) {
      invalidToken();
      navigate(`/login?redirectTo=${encodeURIComponent(window.location.pathname)}`);
    }
  }, [isAuthenticated, navigate]);

  const toView = useCallback(async (viewId: string) => {
    localStorage.setItem('last_view_id', viewId);
    navigate(`/app/${currentWorkspaceId}/${viewId}`);
  }, [currentWorkspaceId, navigate]);

  useEffect(() => {
    if (!currentWorkspaceId) return;
    if (pathname === '/app/trash') return;

    if (params.viewId) {
      localStorage.setItem('last_view_id', params.viewId);
      return;
    }

    const lastViewId = localStorage.getItem('last_view_id');

    if (lastViewId) {
      void toView(lastViewId);
      return;
    }

    const firstSpace = outline?.[0];
    const firstView = firstSpace?.children?.[0];

    if (firstView) {
      void toView(firstView.view_id);
    }
  }, [pathname, currentWorkspaceId, outline, params.viewId, toView]);

  const loadViewMeta = useCallback(async (viewId: string, callback?: (meta: View) => void) => {
    const view = findView(outline || [], viewId);

    if (!view) {
      return Promise.reject('View not found');
    }

    if (callback) {
      callback(view);
    }

    return view;
  }, [outline]);

  const loadView = useCallback(async (viewId: string) => {

    try {
      if (!service || !currentWorkspaceId) {
        throw new Error('Service or workspace not found');
      }

      const res = await service?.getPageDoc(currentWorkspaceId, viewId);

      if (!res) {
        throw new Error('View not found');
      }

      return res;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service]);

  const getViewRowsMap = useCallback(async (viewId: string) => {
    try {
      if (!service || !currentWorkspaceId) {
        throw new Error('Service or workspace not found');
      }

      const res = await service?.getDatabasePageRows(currentWorkspaceId, viewId);

      if (!res) {
        throw new Error('View rows not found');
      }

      return res;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service]);

  const loadOutline = useCallback(async () => {

    if (!service || !currentWorkspaceId) return;
    try {
      const res = await service?.getAppOutline(currentWorkspaceId);

      if (!res) {
        throw new Error('App outline not found');
      }

      setOutline(res);
    } catch (e) {
      notify.error('App outline not found');
    }
  }, [currentWorkspaceId, service]);

  const loadFavoriteViews = useCallback(async () => {
    if (!service || !currentWorkspaceId) return;
    try {
      const res = await service?.getAppFavorites(currentWorkspaceId);

      if (!res) {
        throw new Error('Favorite views not found');
      }

      setFavoriteViews(res);
    } catch (e) {
      notify.error('Favorite views not found');
    }
  }, [currentWorkspaceId, service]);

  const loadRecentViews = useCallback(async () => {
    if (!service || !currentWorkspaceId) return;
    try {
      const res = await service?.getAppRecent(currentWorkspaceId);

      if (!res) {
        throw new Error('Recent views not found');
      }

      setRecentViews(uniqBy(res, 'view_id'));
    } catch (e) {
      notify.error('Recent views not found');
    }
  }, [currentWorkspaceId, service]);

  useEffect(() => {
    void loadOutline();
  }, [loadOutline]);

  return <AppContext.Provider
    value={{
      currentWorkspaceId,
      outline,
      viewId,
      toView,
      loadViewMeta,
      getViewRowsMap,
      loadView,
      loadFavoriteViews,
      loadRecentViews,
      favoriteViews,
      recentViews,
    }}
  >
    {children}
  </AppContext.Provider>;
};

export function useAppOutline () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppOutline must be used within an AppProvider');
  }

  return context.outline;
}

export function useAppViewId () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppViewId must be used within an AppProvider');
  }

  return context.viewId;
}

export function useCurrentWorkspaceId () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useCurrentWorkspaceId must be used within an AppProvider');
  }

  return context.currentWorkspaceId;
}

export function useAppHandlers () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppHandlers must be used within an AppProvider');
  }

  return {
    toView: context.toView,
    loadViewMeta: context.loadViewMeta,
    getViewRowsMap: context.getViewRowsMap,
    loadView: context.loadView,

  };
}

export function useAppFavorites () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppFavorites must be used within an AppProvider');
  }

  return {
    loadFavoriteViews: context.loadFavoriteViews,
    favoriteViews: context.favoriteViews,
  };
}

export function useAppRecent () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppRecent must be used within an AppProvider');
  }

  return {
    loadRecentViews: context.loadRecentViews,
    recentViews: context.recentViews,
  };
}