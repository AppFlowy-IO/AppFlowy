import { invalidToken } from '@/application/session/token';
import {
  AppendBreadcrumb, CreatePagePayload,
  CreateRowDoc, CreateSpacePayload,
  DatabaseRelations,
  LoadView,
  LoadViewMeta,
  Types,
  UIVariant,
  UpdatePagePayload, UpdateSpacePayload,
  UserWorkspaceInfo,
  View,
  ViewLayout,
  YjsDatabaseKey,
  YjsEditorKey,
  YSharedRoot,
} from '@/application/types';
import { findAncestors, findView, findViewByLayout } from '@/components/_shared/outline/utils';
import RequestAccess from '@/components/app/landing-pages/RequestAccess';
import { AFConfigContext, useService } from '@/components/main/app.hooks';
import { TextCount } from '@/utils/word';
import { sortBy, uniqBy } from 'lodash-es';
import React, { createContext, Suspense, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { validate as uuidValidate } from 'uuid';

const ViewModal = React.lazy(() => import('@/components/app/ViewModal'));

export interface AppContextType {
  toView: (viewId: string, blockId?: string, keepSearch?: boolean) => Promise<void>;
  loadViewMeta: LoadViewMeta;
  createRowDoc?: CreateRowDoc;
  loadView: LoadView;
  outline?: View[];
  viewId?: string;
  wordCount?: Record<string, TextCount>;
  setWordCount?: (viewId: string, count: TextCount) => void;
  currentWorkspaceId?: string;
  onChangeWorkspace?: (workspaceId: string) => Promise<void>;
  userWorkspaceInfo?: UserWorkspaceInfo;
  breadcrumbs?: View[];
  appendBreadcrumb?: AppendBreadcrumb;
  loadFavoriteViews?: () => Promise<View[] | undefined>;
  loadRecentViews?: () => Promise<View[] | undefined>;
  loadTrash?: (workspaceId: string) => Promise<void>;
  favoriteViews?: View[];
  recentViews?: View[];
  trashList?: View[];
  rendered?: boolean;
  onRendered?: () => void;
  notFound?: boolean;
  viewHasBeenDeleted?: boolean;
  addPage?: (parentId: string, payload: CreatePagePayload) => Promise<string>;
  deletePage?: (viewId: string) => Promise<void>;
  updatePage?: (viewId: string, payload: UpdatePagePayload) => Promise<void>;
  deleteTrash?: (viewId?: string) => Promise<void>;
  restorePage?: (viewId?: string) => Promise<void>;
  movePage?: (viewId: string, parentId: string, prevViewId?: string) => Promise<void>;
  openPageModal?: (viewId: string) => void;
  openPageModalViewId?: string;
  loadViews?: (variant?: UIVariant) => Promise<View[] | undefined>;
  createSpace?: (payload: CreateSpacePayload) => Promise<string>;
  updateSpace?: (payload: UpdateSpacePayload) => Promise<void>;
  uploadFile?: (viewId: string, file: File, onProgress?: (n: number) => void) => Promise<string>;
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
  const [openModalViewId, setOpenModalViewId] = useState<string | undefined>(undefined);
  const wordCountRef = useRef<Record<string, TextCount>>({});
  const setWordCount = useCallback((viewId: string, count: TextCount) => {
    wordCountRef.current[viewId] = count;
  }, []);

  const [userWorkspaceInfo, setUserWorkspaceInfo] = useState<UserWorkspaceInfo | undefined>(undefined);
  const currentWorkspaceId = useMemo(() => params.workspaceId || userWorkspaceInfo?.selectedWorkspace.id, [params.workspaceId, userWorkspaceInfo?.selectedWorkspace.id]);
  const [workspaceDatabases, setWorkspaceDatabases] = useState<DatabaseRelations | undefined>(undefined);
  const [outline, setOutline] = useState<View[]>();
  const [favoriteViews, setFavoriteViews] = useState<View[]>();
  const [recentViews, setRecentViews] = useState<View[]>();
  const [trashList, setTrashList] = React.useState<View[]>();
  const viewHasBeenDeleted = useMemo(() => {
    if (!viewId) return false;
    return trashList?.some((v) => v.view_id === viewId);
  }, [trashList, viewId]);
  const viewNotFound = useMemo(() => {
    if (!viewId || !outline) return false;
    return !findView(outline, viewId);
  }, [outline, viewId]);

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
    navigate(`/login?redirectTo=${encodeURIComponent(window.location.href)}`);
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

  const toView = useCallback(async (viewId: string, blockId?: string, keepSearch?: boolean) => {
    let url = `/app/${currentWorkspaceId}/${viewId}`;
    const view = await loadViewMeta(viewId);

    const searchParams = new URLSearchParams(keepSearch ? window.location.search : undefined);

    if (blockId) {
      switch (view.layout) {
        case ViewLayout.Document:
          searchParams.set('blockId', blockId);
          break;
        case ViewLayout.Grid:
        case ViewLayout.Board:
        case ViewLayout.Calendar:
          searchParams.set('r', blockId);
          break;
        default:
          break;
      }
    }

    if (searchParams.toString()) {
      url += `?${searchParams.toString()}`;
    }

    navigate(url);
  }, [currentWorkspaceId, loadViewMeta, navigate]);

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

      const sharedRoot = res.get(YjsEditorKey.data_section) as YSharedRoot;
      let objectId = id;
      let collabType = Types.Document;

      if (sharedRoot.has(YjsEditorKey.database)) {
        const database = sharedRoot.get(YjsEditorKey.database);

        objectId = database?.get(YjsDatabaseKey.id);
        collabType = Types.Database;
      }

      service.registerDocUpdate(res, {
        workspaceId: currentWorkspaceId,
        objectId,
        collabType,
      });

      return res;
      // eslint-disable-next-line
    } catch (e: any) {
      errorCallback(e);

      return Promise.reject(e);
    }
  }, [viewId, currentWorkspaceId, service]);

  const createRowDoc = useCallback(
    async (rowKey: string) => {
      if (!currentWorkspaceId || !service) {
        throw new Error('Failed to create row doc');
      }

      try {
        const doc = await service.createRowDoc(rowKey);

        if (!doc) {
          throw new Error('Failed to create row doc');
        }

        service.registerDocUpdate(doc, {
          workspaceId: currentWorkspaceId,
          objectId: rowKey,
          collabType: Types.DatabaseRow,
        });

        createdRowKeys.current.push(rowKey);
        return doc;
      } catch (e) {
        return Promise.reject(e);
      }
    },
    [currentWorkspaceId, service],
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

  const loadOutline = useCallback(async (workspaceId: string, force = true) => {

    if (!service) return;
    try {
      const res = await service?.getAppOutline(workspaceId);

      if (!res) {
        throw new Error('App outline not found');
      }

      setOutline(res);
      if (!force) return;

      const firstView = findViewByLayout(res, [ViewLayout.Document, ViewLayout.Board, ViewLayout.Grid, ViewLayout.Calendar]);

      if (!firstView) {
        setRendered(true);
      }

      try {

        await service.openWorkspace(workspaceId);
        const wId = window.location.pathname.split('/')[2];
        const pageId = window.location.pathname.split('/')[3];
        const search = window.location.search;

        // skip /app/trash and /app/*other-pages
        if (wId && !uuidValidate(wId)) {
          return;
        }

        // skip /app/:workspaceId/:pageId
        if (pageId && uuidValidate(pageId) && wId && uuidValidate(wId) && wId === workspaceId) {
          return;
        }

        const lastViewId = localStorage.getItem('last_view_id');

        if (lastViewId && findView(res, lastViewId)) {
          navigate(`/app/${workspaceId}/${lastViewId}${search}`);

        } else if (firstView) {
          navigate(`/app/${workspaceId}/${firstView.view_id}${search}`);
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
      return res;
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

      const views = uniqBy(res, 'view_id');

      setRecentViews(views);
      return views;
    } catch (e) {
      console.error('Recent views not found');
    }
  }, [currentWorkspaceId, service]);

  const loadTrash = useCallback(async (currentWorkspaceId: string) => {

    if (!service) return;
    try {
      const res = await service?.getAppTrash(currentWorkspaceId);

      if (!res) {
        throw new Error('App trash not found');
      }

      setTrashList(sortBy(uniqBy(res, 'view_id'), 'last_edited_time').reverse());
    } catch (e) {
      return Promise.reject('App trash not found');
    }
  }, [service]);

  useEffect(() => {
    if (!currentWorkspaceId) return;
    void loadOutline(currentWorkspaceId);
    void (async () => {
      try {
        await loadTrash(currentWorkspaceId);
      } catch (e) {
        console.error(e);
      }
    })();
  }, [loadOutline, currentWorkspaceId, loadTrash]);

  useEffect(() => {
    void loadUserWorkspaceInfo().then(res => {
      const selectedWorkspace = res?.selectedWorkspace;

      if (!selectedWorkspace) return;

      void loadDatabaseViewRelations(selectedWorkspace.id, selectedWorkspace.databaseStorageId);
    });
  }, [loadDatabaseViewRelations, loadUserWorkspaceInfo]);

  const onChangeWorkspace = useCallback(async (workspaceId: string) => {
    if (!service) return;
    if (userWorkspaceInfo && !userWorkspaceInfo.workspaces.some((w) => w.id === workspaceId)) {
      window.location.href = `/app/${workspaceId}`;
      return;
    }

    await service.openWorkspace(workspaceId);
    await loadUserWorkspaceInfo();
    localStorage.removeItem('last_view_id');
    setOutline(undefined);
    navigate(`/app/${workspaceId}`);

  }, [navigate, service, userWorkspaceInfo, loadUserWorkspaceInfo]);

  const addPage = useCallback(async (parentViewId: string, payload: CreatePagePayload) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      const viewId = await service.addAppPage(currentWorkspaceId, parentViewId, payload);

      void loadOutline(currentWorkspaceId, false);

      return viewId;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, loadOutline]);

  const openPageModal = useCallback((viewId: string) => {
    setOpenModalViewId(viewId);
  }, []);

  const deletePage = useCallback(async (id: string) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      await service.moveToTrash(currentWorkspaceId, id);
      void loadTrash(currentWorkspaceId);
      void loadOutline(currentWorkspaceId, false);
      return;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, loadTrash, loadOutline]);

  const deleteTrash = useCallback(async (viewId?: string) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      await service.deleteTrash(currentWorkspaceId, viewId);

      void loadOutline(currentWorkspaceId, false);
      return;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, loadOutline]);

  const restorePage = useCallback(async (viewId?: string) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      await service.restoreFromTrash(currentWorkspaceId, viewId);

      void loadOutline(currentWorkspaceId, false);
      return;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, loadOutline]);

  const updatePage = useCallback(async (viewId: string, payload: UpdatePagePayload) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      await service.updateAppPage(currentWorkspaceId, viewId, payload);

      void loadOutline(currentWorkspaceId, false);
      return;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, loadOutline]);

  const movePage = useCallback(async (viewId: string, parentId: string, prevViewId?: string) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      const lastChild = findView(outline || [], parentId)?.children?.slice(-1)[0];
      const prevId = prevViewId || lastChild?.view_id;

      await service.movePage(currentWorkspaceId, viewId, parentId, prevId);

      void loadOutline(currentWorkspaceId, false);
      return;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, outline, loadOutline]);

  const loadViews = useCallback(async (varient?: UIVariant) => {
    if (!varient) {
      return outline || [];
    }

    if (varient === UIVariant.Favorite) {
      if (favoriteViews && favoriteViews.length > 0) {
        return favoriteViews || [];
      } else {
        return loadFavoriteViews();
      }
    }

    if (varient === UIVariant.Recent) {
      if (recentViews && recentViews.length > 0) {
        return recentViews || [];
      } else {
        return loadRecentViews();
      }
    }

    return [];
  }, [favoriteViews, loadFavoriteViews, loadRecentViews, outline, recentViews]);

  const createSpace = useCallback(async (payload: CreateSpacePayload) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      const res = await service.createSpace(currentWorkspaceId, payload);

      void loadOutline(currentWorkspaceId, false);
      return res;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, loadOutline]);

  const updateSpace = useCallback(async (payload: UpdateSpacePayload) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      const res = await service.updateSpace(currentWorkspaceId, payload);

      void loadOutline(currentWorkspaceId, false);
      return res;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service, loadOutline]);

  const uploadFile = useCallback(async (viewId: string, file: File, onProgress?: (n: number) => void) => {
    if (!currentWorkspaceId || !service) {
      throw new Error('No workspace or service found');
    }

    try {
      const res = await service.uploadFile(currentWorkspaceId, viewId, file, onProgress);

      return res;
    } catch (e) {
      return Promise.reject(e);
    }
  }, [currentWorkspaceId, service]);

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
      loadTrash,
      favoriteViews,
      recentViews,
      trashList,
      appendBreadcrumb,
      breadcrumbs,
      userWorkspaceInfo,
      onChangeWorkspace,
      rendered,
      onRendered,
      notFound: viewNotFound,
      viewHasBeenDeleted,
      addPage,
      openPageModal,
      openPageModalViewId: openModalViewId,
      deletePage,
      deleteTrash,
      updatePage,
      movePage,
      restorePage,
      loadViews,
      wordCount: wordCountRef.current,
      setWordCount,
      createSpace,
      updateSpace,
      uploadFile,
    }}
  >
    {requestAccessOpened ? <RequestAccess/> : children}
    {<Suspense>
      <ViewModal
        open={!!openModalViewId}
        viewId={openModalViewId}
        onClose={() => {
          setOpenModalViewId(undefined);
        }}
      />
    </Suspense>}
  </AppContext.Provider>;
};

export function useViewErrorStatus() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useViewErrorStatus must be used within an AppProvider');
  }

  return {
    notFound: context.notFound,
    deleted: context.viewHasBeenDeleted,
  };
}

export function useBreadcrumb() {
  const context = useContext(AppContext);

  return context?.breadcrumbs;
}

export function useUserWorkspaceInfo() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useUserWorkspaceInfo must be used within an AppProvider');
  }

  return context.userWorkspaceInfo;
}

export function useAppOutline() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppOutline must be used within an AppProvider');
  }

  return context.outline;
}

export function useAppViewId() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppViewId must be used within an AppProvider');
  }

  return context.viewId;
}

export function useAppWordCount(viewId?: string | null) {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppWordCount must be used within an AppProvider');
  }

  if (!viewId) {
    return;
  }

  return context.wordCount?.[viewId];
}

export function useOpenModalViewId() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useOpenModalViewId must be used within an AppProvider');
  }

  return context.openPageModalViewId;
}

export function useAppView(viewId?: string) {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppView must be used within an AppProvider');
  }

  if (!viewId) {
    return;
  }

  return findView(context.outline || [], viewId);
}

export function useCurrentWorkspaceId() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useCurrentWorkspaceId must be used within an AppProvider');
  }

  return context.currentWorkspaceId;
}

export function useAppHandlers() {
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
    addPage: context.addPage,
    openPageModal: context.openPageModal,
    deletePage: context.deletePage,
    deleteTrash: context.deleteTrash,
    restorePage: context.restorePage,
    updatePage: context.updatePage,
    movePage: context.movePage,
    loadViews: context.loadViews,
    setWordCount: context.setWordCount,
    createSpace: context.createSpace,
    updateSpace: context.updateSpace,
    uploadFile: context.uploadFile,
  };
}

export function useAppFavorites() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppFavorites must be used within an AppProvider');
  }

  return {
    loadFavoriteViews: context.loadFavoriteViews,
    favoriteViews: context.favoriteViews,
  };
}

export function useAppRecent() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppRecent must be used within an AppProvider');
  }

  return {
    loadRecentViews: context.loadRecentViews,
    recentViews: context.recentViews,
  };
}

export function useAppTrash() {
  const context = useContext(AppContext);

  if (!context) {
    throw new Error('useAppTrash must be used within an AppProvider');
  }

  return {
    loadTrash: context.loadTrash,
    trashList: context.trashList,
  };
}