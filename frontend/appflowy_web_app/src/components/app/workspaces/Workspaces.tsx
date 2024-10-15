import { invalidToken } from '@/application/session/token';
import { Workspace } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { Popover, RichTooltip } from '@/components/_shared/popover';
import { getAvatar } from '@/components/_shared/view-icon/utils';
import { useAppHandlers, useCurrentWorkspaceId, useUserWorkspaceInfo } from '@/components/app/app.hooks';
import { useCurrentUser } from '@/components/main/app.hooks';
import { Avatar, Button, Divider, IconButton, Tooltip } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useMemo } from 'react';
import { ReactComponent as ArrowRightSvg } from '@/assets/arrow_right.svg';
import { ReactComponent as AppFlowyLogo } from '@/assets/appflowy.svg';
import { ReactComponent as SelectedSvg } from '@/assets/selected.svg';
import { ReactComponent as MoreSvg } from '@/assets/more.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as LoginIcon } from '@/assets/login.svg';
import { useNavigate } from 'react-router-dom';

export function Workspaces () {
  const { t } = useTranslation();
  const userWorkspaceInfo = useUserWorkspaceInfo();
  const currentWorkspaceId = useCurrentWorkspaceId();
  const currentUser = useCurrentUser();
  const [hoveredHeader, setHoveredHeader] = React.useState<boolean>(false);
  const [open, setOpen] = React.useState(false);
  const ref = React.useRef<HTMLButtonElement | null>(null);
  const navigate = useNavigate();
  const [moreOpen, setMoreOpen] = React.useState(false);
  const [changeLoading, setChangeLoading] = React.useState<string | null>(null);
  const handleLogin = useCallback(() => {
    invalidToken();
    navigate('/login?redirectTo=' + encodeURIComponent(window.location.href));
  }, [navigate]);

  const {
    onChangeWorkspace: handleSelectedWorkspace,
  } = useAppHandlers();

  const selectedWorkspace = useMemo(() => {
    return userWorkspaceInfo?.workspaces.find((workspace) => workspace.id === currentWorkspaceId);
  }, [currentWorkspaceId, userWorkspaceInfo]);

  const getAvatarProps = useCallback((workspace: Workspace) => {
    return getAvatar({
      icon: workspace.icon,
      name: workspace.name,
    });

  }, []);

  const handleChange = useCallback(async (selectedId: string) => {
    setChangeLoading(selectedId);
    try {
      await handleSelectedWorkspace?.(selectedId);
    } catch (e) {
      notify.error('Failed to change workspace');
    }

    setChangeLoading(null);
  }, [handleSelectedWorkspace]);

  if (!userWorkspaceInfo || !selectedWorkspace) return <div
    className={'flex p-4 cursor-pointer items-center gap-1 text-text-title'}
    onClick={async () => {
      const selectedId = userWorkspaceInfo?.selectedWorkspace?.id || userWorkspaceInfo?.workspaces[0]?.id;

      if (!selectedId) return;

      void handleChange(selectedId);
    }}
  >
    <AppFlowyLogo className={'w-[88px]'} />
  </div>;

  return <>
    <Button
      ref={ref}
      onMouseLeave={() => setHoveredHeader(false)}
      onMouseEnter={() => setHoveredHeader(true)}
      onClick={() => setOpen(true)}
      className={'flex px-1 w-full cursor-pointer justify-start py-1 items-center gap-1 mx-2 text-text-title'}
    >
      <div className={'flex items-center gap-1.5 text-text-title overflow-hidden'}>
        <Avatar
          variant={'rounded'}
          className={`w-6 h-6 border border-line-divider rounded-[8px] p-1 ${selectedWorkspace.icon ? 'bg-transparent' : ''}`}
          {...getAvatarProps(selectedWorkspace)}
        />
        <div className={'text-text-title flex-1 truncate font-semibold'}>{selectedWorkspace.name}</div>
        {hoveredHeader && <ArrowRightSvg className={'w-4 h-4 transform rotate-90'} />}
      </div>
    </Button>
    <Popover open={open} anchorEl={ref.current} onClose={() => setOpen(false)}>
      <div
        className={'flex min-w-[260px] flex-col gap-1 p-2 w-full max-h-[560px] overflow-y-auto overflow-x-hidden appflowy-scroller'}
      >
        <div className={'flex px-1 text-text-caption items-center justify-between'}>
          <span className={'font-medium flex-1 text-sm'}>{currentUser?.email}</span>
          <RichTooltip
            placement={'bottom-start'}
            content={
              <div className={'p-2 w-[160px]'}>
                <Button
                  color={'inherit'} size={'small'} className={'w-full justify-start'} onClick={handleLogin}
                  startIcon={<LoginIcon />}
                >
                  {t('button.logout')}
                </Button>
              </div>

            } open={moreOpen} onClose={() => setMoreOpen(false)}
          >
            <IconButton onClick={() => setMoreOpen(prev => !prev)}>
              <MoreSvg className={'w-4 h-4'} />
            </IconButton>
          </RichTooltip>

        </div>
        <Divider className={'w-full mt-1'} />
        {userWorkspaceInfo.workspaces.map((workspace) => (
          <Button
            key={workspace.id}
            onClick={() => {
              void handleChange(workspace.id);
            }}
            className={'flex px-1.5 w-full cursor-pointer justify-start py-2 items-center gap-1.5 overflow-hidden text-text-title'}
          >
            <Avatar
              variant={'rounded'}
              className={'rounded-[8px] w-7 h-7 border border-line-divider'} {...getAvatarProps(workspace)} />

            <Tooltip title={workspace.name} enterDelay={1000} enterNextDelay={1000}>
              <div className={'text-text-title font-medium truncate flex-1 text-left'}>{workspace.name}</div>
            </Tooltip>
            {changeLoading === workspace.id ? <CircularProgress size={16} /> : workspace.id === selectedWorkspace.id &&
              <SelectedSvg className={'w-4 text-function-success h-4'} />}
          </Button>
        ))}
      </div>
    </Popover>
  </>;
}

export default Workspaces;