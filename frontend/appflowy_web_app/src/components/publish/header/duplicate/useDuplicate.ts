import { AFConfigContext } from '@/components/main/app.hooks';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { SpaceView, Workspace } from '@/application/types';
import { notify } from '@/components/_shared/notify';

export function useDuplicate () {
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated || false;
  const [search, setSearch] = useSearchParams();
  const [loginOpen, setLoginOpen] = React.useState(false);
  const [duplicateOpen, setDuplicateOpen] = React.useState(false);

  useEffect(() => {
    const isDuplicate = search.get('action') === 'duplicate';

    if (!isDuplicate) return;

    setLoginOpen(!isAuthenticated);
    setDuplicateOpen(isAuthenticated);
  }, [isAuthenticated, search, setSearch]);

  const url = window.location.href;

  const handleLoginClose = useCallback(() => {
    setLoginOpen(false);
    setSearch((prev) => {
      prev.delete('action');
      return prev;
    });
  }, [setSearch]);

  const handleDuplicateClose = useCallback(() => {
    setDuplicateOpen(false);
    setSearch((prev) => {
      prev.delete('action');
      return prev;
    });
  }, [setSearch]);

  return {
    loginOpen,
    handleLoginClose,
    url,
    duplicateOpen,
    handleDuplicateClose,
  };
}

export function useLoadWorkspaces () {
  const currentUser = useContext(AFConfigContext)?.currentUser;
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated && Boolean(currentUser) || false;
  const [spaceLoading, setSpaceLoading] = useState<boolean>(false);
  const [workspaceLoading, setWorkspaceLoading] = useState<boolean>(false);
  const [selectedWorkspaceId, setSelectedWorkspaceId] = useState<string>(() => {
    return localStorage.getItem('duplicate_selected_workspace') || '';
  });
  const [selectedSpaceId, setSelectedSpaceId] = useState<string>('');

  const [workspaceList, setWorkspaceList] = useState<Workspace[]>([]);

  const [spaceList, setSpaceList] = useState<SpaceView[]>([]);

  const service = useContext(AFConfigContext)?.service;

  const loadWorkspaces = useCallback(async () => {
    if (!isAuthenticated) return;
    setWorkspaceLoading(true);
    try {
      const workspaces = await service?.getWorkspaces();

      if (workspaces) {
        setWorkspaceList(workspaces);
        setSelectedWorkspaceId(prev => {
          if (!prev || !workspaces.find(item => item.id === prev)) return workspaces[0].id;
          return prev;
        });
      } else {
        setWorkspaceList([]);
        setSelectedWorkspaceId('');
      }
    } catch (e) {
      notify.error('Failed to load workspaces');
    } finally {
      setWorkspaceLoading(false);
    }
  }, [service, isAuthenticated]);

  const loadSpaces = useCallback(
    async (selectedWorkspaceId: string) => {
      if (!isAuthenticated) return;
      setSpaceLoading(true);
      try {
        const folder = await service?.getWorkspaceFolder(selectedWorkspaceId);

        if (folder) {
          const spaces = [];

          for (const child of folder.children) {
            if (child.isSpace) {
              spaces.push({
                id: child.id,
                name: child.name,
                isPrivate: child.isPrivate,
                extra: child.extra,
              });
            }
          }

          setSpaceList(spaces);
        } else {
          setSpaceList([]);
        }
      } catch (e) {
        notify.error('Failed to load spaces');
      } finally {
        setSelectedSpaceId('');
        setSpaceLoading(false);
      }
    },
    [service, isAuthenticated],
  );

  return {
    workspaceList,
    spaceList,
    selectedWorkspaceId,
    setSelectedWorkspaceId,
    selectedSpaceId,
    setSelectedSpaceId,
    workspaceLoading,
    spaceLoading,
    loadWorkspaces,
    loadSpaces,
  };
}