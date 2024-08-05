import React, { useCallback, useContext, useEffect, useState } from 'react';
import { AFConfigContext } from '@/components/app/AppConfig';
import { useSearchParams } from 'react-router-dom';
import { SpaceView, Workspace } from '@/application/types';
import { notify } from '@/components/_shared/notify';

export function useDuplicate() {
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

export function useLoadWorkspaces() {
  const [spaceLoading, setSpaceLoading] = useState<boolean>(false);
  const [workspaceLoading, setWorkspaceLoading] = useState<boolean>(false);
  const [selectedWorkspaceId, setSelectedWorkspaceId] = useState<string>('1');
  const [selectedSpaceId, setSelectedSpaceId] = useState<string>('1');

  const [workspaceList, setWorkspaceList] = useState<Workspace[]>([]);

  const [spaceList, setSpaceList] = useState<SpaceView[]>([]);

  const service = useContext(AFConfigContext)?.service;

  useEffect(() => {
    void (async () => {
      setWorkspaceLoading(true);
      try {
        const workspaces = await service?.getWorkspaces();

        if (workspaces) {
          setWorkspaceList(workspaces);
          setSelectedWorkspaceId(workspaces[0].id);
        } else {
          setWorkspaceList([]);
          setSelectedWorkspaceId('');
        }
      } catch (e) {
        notify.error('Failed to load workspaces');
      } finally {
        setWorkspaceLoading(false);
      }
    })();
  }, [service]);

  useEffect(() => {
    if (workspaceList.length === 0 || !selectedWorkspaceId || workspaceLoading) {
      setSpaceList([]);
      setSelectedSpaceId('');
      return;
    }

    setSpaceLoading(true);
    void (async () => {
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
    })();
  }, [selectedWorkspaceId, service, workspaceList.length, workspaceLoading]);

  return {
    workspaceList,
    spaceList,
    selectedWorkspaceId,
    setSelectedWorkspaceId,
    selectedSpaceId,
    setSelectedSpaceId,
    workspaceLoading,
    spaceLoading,
  };
}
