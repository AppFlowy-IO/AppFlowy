import { Workspace } from '@/application/types';
import { getAvatarProps } from '@/components/app/workspaces/utils';
import { useService } from '@/components/main/app.hooks';
import { Avatar, Button, Tooltip } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as SelectedSvg } from '@/assets/selected.svg';

function WorkspaceList ({
  defaultWorkspaces,
  currentWorkspaceId,
  onChange,
  changeLoading,
}: {
  currentWorkspaceId?: string;
  changeLoading?: string;
  onChange: (selectedId: string) => void;
  defaultWorkspaces?: Workspace[];
}) {
  const service = useService();
  const { t } = useTranslation();
  const [workspaces, setWorkspaces] = React.useState<Workspace[]>(defaultWorkspaces || []);
  const fetchWorkspaces = useCallback(async () => {
    if (!service) return;
    try {
      const workspaces = await service.getWorkspaces();

      setWorkspaces(workspaces);
    } catch (e) {
      console.error(e);
    }
  }, [service]);

  useEffect(() => {
    void fetchWorkspaces();
  }, [fetchWorkspaces]);

  return (
    <>
      {workspaces.map((workspace) => {
        return <Button
          key={workspace.id}
          className={'flex relative text-[1em] items-center justify-between gap-4 p-2 cursor-pointer'}
          onClick={async () => {
            if (workspace.id === currentWorkspaceId) return;

            void onChange(workspace.id);
          }}
        >
          <Avatar
            variant={'rounded'}
            className={'rounded-[8px] text-[1.2em] w-[2em] h-[2em] border border-line-divider'} {...getAvatarProps(workspace)} />
          <div className={'flex-1 overflow-hidden flex flex-col items-start'}>
            <Tooltip
              title={workspace.name}
              enterDelay={1000}
              enterNextDelay={1000}
            >
              <div className={'text-text-title font-medium truncate flex-1 text-left'}>{workspace.name}</div>
            </Tooltip>
            <div className={'text-text-caption text-[0.85em]'}>
              {t('members', { count: workspace.memberCount || 0 })}
            </div>
          </div>
          {changeLoading === workspace.id ?
            <CircularProgress size={16} /> : workspace.id === currentWorkspaceId &&
            <SelectedSvg className={'w-6 text-fill-default h-6'} />}
        </Button>;
      })}
    </>
  );
}

export default WorkspaceList;