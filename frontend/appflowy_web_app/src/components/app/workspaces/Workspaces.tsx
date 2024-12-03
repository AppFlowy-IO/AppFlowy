import { invalidToken } from '@/application/session/token';
import Import from '@/components/_shared/more-actions/importer/Import';
import { notify } from '@/components/_shared/notify';
import { Popover, RichTooltip } from '@/components/_shared/popover';
import { useAppHandlers, useCurrentWorkspaceId, useUserWorkspaceInfo } from '@/components/app/app.hooks';
import CurrentWorkspace from '@/components/app/workspaces/CurrentWorkspace';
import WorkspaceList from '@/components/app/workspaces/WorkspaceList';
import { useCurrentUser } from '@/components/main/app.hooks';
import { openUrl } from '@/utils/url';
import { Button, Divider, IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useMemo } from 'react';
import { ReactComponent as ArrowRightSvg } from '@/assets/arrow_right.svg';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { ReactComponent as MoreSvg } from '@/assets/more.svg';
import { ReactComponent as TipIcon } from '@/assets/warning.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as LoginIcon } from '@/assets/login.svg';
import { useNavigate, useSearchParams } from 'react-router-dom';

export function Workspaces () {
  const { t } = useTranslation();
  const userWorkspaceInfo = useUserWorkspaceInfo();
  const currentWorkspaceId = useCurrentWorkspaceId();
  const currentUser = useCurrentUser();
  const [open, setOpen] = React.useState(false);
  const [hoveredHeader, setHoveredHeader] = React.useState<boolean>(false);
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

  const handleChange = useCallback(async (selectedId: string) => {
    setChangeLoading(selectedId);
    try {
      await handleSelectedWorkspace?.(selectedId);
    } catch (e) {
      notify.error('Failed to change workspace');
    }

    setChangeLoading(null);
  }, [handleSelectedWorkspace]);
  const [, setSearchParams] = useSearchParams();

  const handleOpenImport = useCallback(() => {
    setSearchParams(prev => {
      prev.set('action', 'import');
      prev.set('source', 'notion');
      return prev;
    });
  }, [setSearchParams]);

  return <>
    <Button
      ref={ref}
      onMouseLeave={() => setHoveredHeader(false)}
      onMouseEnter={() => setHoveredHeader(true)}
      onClick={() => setOpen(true)}
      className={'flex px-1 w-full cursor-pointer justify-start py-1 items-center gap-1 mx-2 text-text-title'}
    >
      <div className={'flex items-center gap-1.5 text-text-title overflow-hidden'}>
        <CurrentWorkspace
          userWorkspaceInfo={userWorkspaceInfo}
          selectedWorkspace={selectedWorkspace}
          onChangeWorkspace={handleChange}
        />

        {hoveredHeader && <ArrowRightSvg className={'w-4 h-4 transform rotate-90'} />}
      </div>
    </Button>
    <Popover
      open={open}
      anchorEl={ref.current}
      onClose={() => setOpen(false)}
    >
      <div
        className={'flex text-[14px] min-w-[260px] max-w-[300px] flex-col gap-1 p-2 w-full max-h-[560px] overflow-y-auto overflow-x-hidden appflowy-scroller'}
      >
        <div className={'flex px-1 text-text-caption items-center justify-between'}>
          <span className={'font-medium flex-1 text-sm'}>{currentUser?.email}</span>
          <RichTooltip
            placement={'bottom-start'}
            content={
              <div className={'p-2 w-[160px]'}>
                <Button
                  color={'inherit'}
                  size={'small'}
                  className={'w-full justify-start'}
                  onClick={handleLogin}
                  startIcon={<LoginIcon />}
                >
                  {t('button.logout')}
                </Button>
              </div>
            }
            open={moreOpen}
            onClose={() => setMoreOpen(false)}
          >
            <IconButton onClick={() => setMoreOpen(prev => !prev)}>
              <MoreSvg className={'w-4 h-4'} />
            </IconButton>
          </RichTooltip>

        </div>
        <Divider className={'w-full mt-1'} />
        {open && <WorkspaceList
          defaultWorkspaces={userWorkspaceInfo?.workspaces}
          currentWorkspaceId={currentWorkspaceId}
          onChange={handleChange}
          changeLoading={changeLoading || undefined}
        />}

      </div>
      <Divider className={'w-full'} />
      <div className={'p-1.5 w-full'}>
        <Button
          size={'small'}
          startIcon={<AddIcon />}
          color={'inherit'}
          className={'justify-start px-4 w-full overflow-hidden'}
          onClick={handleOpenImport}
        >
          <div className={'flex-1 text-left'}>{t('web.importNotion')}</div>
          <Tooltip
            title={t('workspace.learnMore')}
            enterDelay={1000}
            enterNextDelay={1000}
          >
            <IconButton
              onClick={(e) => {
                e.stopPropagation();
                void openUrl('https://docs.appflowy.io/docs/guides/import-from-notion', '_blank');
              }}
              size={'small'}
            >
              <TipIcon className={'w-4 h-4'} />
            </IconButton>
          </Tooltip>
        </Button>
      </div>

    </Popover>
    <Import />
  </>;
}

export default Workspaces;