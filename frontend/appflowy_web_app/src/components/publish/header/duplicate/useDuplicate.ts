import React, { useCallback, useContext, useEffect, useState } from 'react';
import { AFConfigContext } from '@/components/app/AppConfig';
import { useSearchParams } from 'react-router-dom';
import { SpaceView, Workspace } from '@/application/types';

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
  const [selectedWorkspaceId, setSelectedWorkspaceId] = useState<string>('1');
  const [selectedSpaceId, setSelectedSpaceId] = useState<string>('1');

  const [workspaceList] = useState<Workspace[]>([
    {
      icon: '😊',
      id: '1',
      name: 'AppFlowy',
      memberCount: 0,
    },
    {
      icon: '😍',
      id: '2',
      name: `Kilu's Workspace`,
      memberCount: 12,
    },
    {
      icon: '😎',
      id: '3',
      name: 'Workspace 3 djskh dhjsa dhsjkahdkja dshjkahd kashdjkashd askhdkjas',
      memberCount: 5,
    },
    {
      icon: '😇',
      id: '4',
      name: 'Workspace 4',
      memberCount: 3,
    },
    {
      icon: '😜',
      id: '5',
      name: 'Workspace 5',
      memberCount: 1,
    },
    {
      icon: '😉',
      id: '6',
      name: 'Workspace 6',
      memberCount: 0,
    },
  ]);

  const [spaceList] = useState<SpaceView[]>([
    {
      id: '1',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_1',
        space_icon_color: 'appflowy_them_color_tint2',
      }),
      name: 'Space 1',
    },
    {
      id: '2',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_2',
        space_icon_color: 'appflowy_them_color_tint1',
      }),
      name: 'Space 2 djisa djiso adiohjsa hdiosahdk ksahkjdhskjahdaskj',
    },
    {
      id: '3',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_3',
        space_icon_color: 'appflowy_them_color_tint3',
      }),
      name: 'Space 3',
    },
    {
      id: '4',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_4',
        space_icon_color: 'appflowy_them_color_tint4',
      }),
      name: 'Space 4',
    },
    {
      id: '5',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_5',
        space_icon_color: 'appflowy_them_color_tint5',
      }),
      name: 'Space 5',
    },
    {
      id: '6',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_6',
        space_icon_color: 'appflowy_them_color_tint6',
      }),
      name: 'Space 6',
    },
    {
      id: '7',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_7',
        space_icon_color: 'appflowy_them_color_tint7',
      }),
      name: 'Space 7',
    },
    {
      id: '8',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_8',
        space_icon_color: 'appflowy_them_color_tint8',
      }),
      name: 'Space 8',
    },
    {
      id: '9',
      extra: JSON.stringify({
        is_space: true,
        space_icon: 'space_icon_9',
        space_icon_color: 'appflowy_them_color_tint9',
      }),
      name: 'Space',
    },
  ]);

  return {
    workspaceList,
    spaceList,
    selectedWorkspaceId,
    setSelectedWorkspaceId,
    selectedSpaceId,
    setSelectedSpaceId,
  };
}
