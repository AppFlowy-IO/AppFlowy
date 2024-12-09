import { invalidToken } from '@/application/session/token';
import Import from '@/components/_shared/more-actions/importer/Import';
import { notify } from '@/components/_shared/notify';
import { Popover } from '@/components/_shared/popover';
import { useAppHandlers, useCurrentWorkspaceId, useUserWorkspaceInfo } from '@/components/app/app.hooks';
import CurrentWorkspace from '@/components/app/workspaces/CurrentWorkspace';
import WorkspaceList from '@/components/app/workspaces/WorkspaceList';
import { useCurrentUser } from '@/components/main/app.hooks';
import { openUrl } from '@/utils/url';
import { Button, Divider, IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useMemo } from 'react';
import { ReactComponent as ArrowRightSvg } from '@/assets/arrow_right.svg';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { ReactComponent as TipIcon } from '@/assets/warning.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as SignOutIcon } from '@/assets/sign_out.svg';
import { useNavigate, useSearchParams } from 'react-router-dom';
import InviteMember from '@/components/app/workspaces/InviteMember';

export function Workspaces () {
  const { t } = useTranslation();
  const userWorkspaceInfo = useUserWorkspaceInfo();
  const currentWorkspaceId = useCurrentWorkspaceId();
  const currentUser = useCurrentUser();
  const [open, setOpen] = React.useState(false);
  const [hoveredHeader, setHoveredHeader] = React.useState<boolean>(false);
  const ref = React.useRef<HTMLButtonElement | null>(null);
  const navigate = useNavigate();
  const [changeLoading, setChangeLoading] = React.useState<string | null>(null);
  const handleSignOut = useCallback(() => {
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
          avatarSize={20}
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
        className={'flex text-[14px] w-[288px] flex-col gap-2 p-2 max-h-[380px] min-h-[303px] overflow-hidden'}
      >
        <div className={'flex p-2 text-text-caption items-center justify-between'}>
          <span className={'font-medium flex-1 text-sm'}>{currentUser?.email}</span>
        </div>
        <div className={'flex flex-1 flex-col gap-1 overflow-y-auto appflowy-scroller'}>
          {open && <WorkspaceList
            defaultWorkspaces={userWorkspaceInfo?.workspaces}
            currentWorkspaceId={currentWorkspaceId}
            onChange={handleChange}
            changeLoading={changeLoading || undefined}
          />}
        </div>

        <Divider className={'w-full mt-1'} />
        {selectedWorkspace && <InviteMember workspace={selectedWorkspace} />}
        <Button
          size={'small'}
          component={'div'}
          startIcon={<AddIcon />}
          color={'inherit'}
          className={'justify-start px-2'}
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
              className={'mx-2'}
            >
              <TipIcon className={'w-4 h-4'} />
            </IconButton>
          </Tooltip>
        </Button>
        <Button
          size={'small'}
          className={'justify-start px-2'}
          color={'inherit'}
          onClick={handleSignOut}
          startIcon={<SignOutIcon />}
        >{t('button.signOut')}</Button>
      </div>

    </Popover>
    <Import />
  </>;
}

export default Workspaces;