import { invalidToken } from '@/application/session/token';
import {
  AppendBreadcrumb,
  CreateRowDoc,
  DatabaseRelations,
  LoadView,
  LoadViewMeta,
  UserWorkspaceInfo,
  View,
  ViewLayout,
} from '@/application/types';
import { findAncestors, findView, findViewByLayout } from '@/components/_shared/outline/utils';
import RequestAccess from '@/components/app/landing-pages/RequestAccess';
import { AFConfigContext, useService } from '@/components/main/app.hooks';
import { uniqBy } from 'lodash-es';
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { validate as uuidValidate } from 'uuid';

export interface AppContextType {
  toView: (viewId: string) => Promise<void>;
  loadViewMeta: LoadViewMeta;
  createRowDoc?: CreateRowDoc;
  loadView: LoadView;
  outline?: View[];
  viewId?: string;
  currentWorkspaceId?: string;
  onChangeWorkspace?: (workspaceId: string) => Promise<void>;
  userWorkspaceInfo?: UserWorkspaceInfo;
  breadcrumbs?: View[];
  appendBreadcrumb?: AppendBreadcrumb;
  loadFavoriteViews?: () => Promise<void>;
  loadRecentViews?: () => Promise<void>;
  favoriteViews?: View[];
  recentViews?: View[];
  rendered?: boolean;
  onRendered?: () => void;
}

const USER_NO_ACCESS_CODE = [1024, 1012];

export const AppContext = createContext<AppContextType | null>(null);

export const AppProvider = ({ children }: { children: React.ReactNode }) => {
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated;
  const params = useParams();
  const viewId = useMemo(() => {
    const id = params.viewId;

    if (id && !uuidValidate(id)) return;
    return id;
  }, [params.viewId]);
  const [userWorkspaceInfo, setUserWorkspaceInfo] = useState<UserWorkspaceInfo | undefined>(undefined);
  const currentWorkspaceId = useMemo(() => params.workspaceId || userWorkspaceInfo?.selectedWorkspace.id, [params.workspaceId, userWorkspaceInfo?.selectedWorkspace.id]);
  const [workspaceDatabases, setWorkspaceDatabases] = useState<DatabaseRelations | undefined>(undefined);
  const [outline, setOutline] = useState<View[]>();
  const [favoriteViews, setFavoriteViews] = useState<View[]>();
  const [recentViews, setRecentViews] = useState<View[]>();
  const createdRowKeys = useRef<string[]>([]);
  const [requestAccessOpened, setRequestAccessOpened] = useState(false);
  const [rendered, setRendered] = useState(false);
  const service = useService();
  const navigate = useNavigate();
  const onRendered = useCallback(() => {
    setRendered(true);
  }, []);
  const logout = useCallback(() => {
    invalidToken();
    navigate(`/login?redirectTo=${encodeURIComponent(window.location.pathname)}`);
  }, [navigate]);

  // If the user is not authenticated, log out the user
  useEffect(() => {
    if (!isAuthenticated) {
      logout();
    }
  }, [isAuthenticated, logout]);

  useEffect(() => {
    const rowKeys = createdRowKeys.current;

    createdRowKeys.current = [];
    if (!rowKeys.length) return;
    rowKeys.forEach((rowKey) => {
      try {
        service?.deleteRowDoc(rowKey);
      } catch (e) {
        console.error(e);
      }
    });

  }, [service, viewId]);

  const originalCrumbs = useMemo(() => {
    if (!outline || !viewId) return [];

    return findAncestors(outline, viewId) || [];
  }, [outline, viewId]);

  const [breadcrumbs, setBreadcrumbs] = useState<View[]>(originalCrumbs);

  useEffect(() => {
    setBreadcrumbs(originalCrumbs);
  }, [originalCrumbs]);

  const appendBreadcrumb = useCallback((view?: View) => {
    setBreadcrumbs((prev) => {
      if (!view) {
        return prev.slice(0, -1);
      }

      const index = prev.findIndex((v) => v.view_id === view.view_id);

      if (index === -1) {
        return [...prev, view];
      }

      const rest = prev.slice(0, index);

      return [...rest, view];
    });
  }, []);

  const toView = useCallback(async (viewId: string, keepSearch?: boolean) => {
    let url = `/app/${currentWorkspaceId}/${viewId}`;

    if (keepSearch) {
      url += window.location.search;
    }

    navigate(url);
  }, [currentWorkspaceId, navigate]);

  const loadViewMeta = useCallback(async (viewId: string, callback?: (meta: View) => void) => {
    const view = findView(outline || [], viewId);

    if (!view) {
      return Promise.reject('View not found');
    }

    if (callback) {
      callback({
        ...view,
        database_relations: workspaceDatabases,
      });
    }

    return {
      ...view,
      database_relations: workspaceDatabases,
    };
  }, [outline, workspaceDatabases]);

  const loadView = useCallback(async (id: string) => {

    const errorCallback = (e: {
      code: number;
    }) => {
      if (viewId === id && USER_NO_ACCESS_CODE.includes(e.code)) {
        setRequestAccessOpened(true);
      }
    };

    try {
      if (!service || !currentWorkspaceId) {
        throw new Error('Service or workspace not found');
      }

      const res = await service?.getPageDoc(currentWorkspaceId, id, errorCallback);

      if (!res) {
        throw new Error('View not found');
      }

      return res;
      // eslint-disable-next-line
    } catch (e: any) {
      errorCallback(e);

      return Promise.reject(e);
    }
  }, [viewId, currentWorkspaceId, service]);

  const createRowDoc = useCallback(
    async (rowKey: string) => {
      try {
        const doc = await service?.createRowDoc(rowKey);

        if (!doc) {
          throw new Error('Failed to create row doc');
        }

        createdRowKeys.current.push(rowKey);
        return doc;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [service],
  );

  const loadUserWorkspaceInfo = useCallback(async () => {
    if (!service) return;
    try {
      const res = await service.getUserWorkspaceInfo();

      setUserWorkspaceInfo(res);
      return res;
    } catch (e) {
      console.error(e);
    }
  }, [service]);
  const loadDatabaseViewRelations = useCallback(async (workspaceId: string, databaseStorageId: string) => {
    if (!service) return;
    try {
      const res = await service.getAppDatabaseViewRelations(workspaceId, databaseStorageId);

      setWorkspaceDatabases(res);
    } catch (e) {
      console.error(e);
    }
  }, [service]);

  const loadOutline = useCallback(async (workspaceId: string) => {

    if (!service) return;
    try {
      const res = await service?.getAppOutline(workspaceId);

      if (!res) {
        throw new Error('App outline not found');
      }

      setOutline(res);
      try {

        await service.openWorkspace(workspaceId);
        const path = window.location.pathname.split('/')[2];

        if (path && !uuidValidate(path)) {
          return;
        }

        const lastViewId = localStorage.getItem('last_view_id');

        if (lastViewId && findView(res, lastViewId)) {
          navigate(`/app/${workspaceId}/${lastViewId}`);

        } else {
          const firstView = findViewByLayout(res, [ViewLayout.Document, ViewLayout.Board, ViewLayout.Grid, ViewLayout.Calendar]);

          if (firstView) {
            navigate(`/app/${workspaceId}/${firstView.view_id}`);
          }
        }

      } catch (e) {
        // do nothing
      }

      // eslint-disable-next-line
    } catch (e: any) {
      console.error('App outline not found');
      if (USER_NO_ACCESS_CODE.includes(e.code)) {
        setRequestAccessOpened(true);
        return;
      }
    }

  }, [navigate, service]);

  const loadFavoriteViews = useCallback(async () => {
    if (!service || !currentWorkspaceId) return;
    try {
      const res = await service?.getAppFavorites(currentWorkspaceId);

      if (!res) {
        throw new Error('Favorite views not found');
      }

      setFavoriteViews(res);
    } catch (e) {
      console.error('Favorite views not found');
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
      console.error('Recent views not found');
    }
  }, [currentWorkspaceId, service]);

  useEffect(() => {
    if (!currentWorkspaceId) return;
    void loadOutline(currentWorkspaceId);

  }, [loadOutline, currentWorkspaceId]);

  useEffect(() => {
    void loadUserWorkspaceInfo().then(res => {
      const selectedWorkspace = res?.selectedWorkspace;

      if (!selectedWorkspace) return;

      void loadDatabaseViewRelations(selectedWorkspace.id, selectedWorkspace.databaseStorageId);
    });
  }, [loadDatabaseViewRelations, loadUserWorkspaceInfo]);

  const onChangeWorkspace = useCallback(async (workspaceId: string) => {
    if (!service) return;
    await service.openWorkspace(workspaceId);
    localStorage.removeItem('last_view_id');
    setOutline(undefined);
    navigate(`/app/${workspaceId}`);

  }, [navigate, service]);

  return <AppContext.Provider
    value={{
      currentWorkspaceId,
      outline,
      viewId,
      toView,
      loadViewMeta,
      createRowDoc,
      loadView,
      loadFavoriteViews,
      loadRecentViews,
      favoriteViews,
      recentViews,
      appendBreadcrumb,
      breadcrumbs,
      userWorkspaceInfo,
      onChangeWorkspace,
      rendered,
      onRendered,
    }}
  >
    {requestAccessOpened ? <RequestAccess /> : children}
  </AppContext.Provider>;
};

export function useBreadcrumb () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useBreadcrumb must be used within an AppProvider');
  }

  return context.breadcrumbs;
}

export function useUserWorkspaceInfo () {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useUserWorkspaceInfo must be used within an AppProvider');
  }

  return context.userWorkspaceInfo;
}

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

export function useAppView () {
  const viewId = useAppViewId();
  const outline = useAppOutline();
  const view = useMemo(() => viewId ? findView(outline || [], viewId) : null, [outline, viewId]);

  if (!viewId || !outline) {
    return;
  }

  return view;
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
    createRowDoc: context.createRowDoc,
    loadView: context.loadView,
    appendBreadcrumb: context.appendBreadcrumb,
    onChangeWorkspace: context.onChangeWorkspace,
    onRendered: context.onRendered,
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