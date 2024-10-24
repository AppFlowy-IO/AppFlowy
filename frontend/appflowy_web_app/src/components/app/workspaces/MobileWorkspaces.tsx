import { MobileDrawer } from '@/components/_shared/mobile-drawer';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useCurrentWorkspaceId, useUserWorkspaceInfo } from '@/components/app/app.hooks';
import CurrentWorkspace from '@/components/app/workspaces/CurrentWorkspace';
import { getAvatarProps } from '@/components/app/workspaces/utils';
import { useCurrentUser } from '@/components/main/app.hooks';
import { Avatar, Divider, IconButton } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useMemo, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as SelectedSvg } from '@/assets/selected.svg';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

function MobileWorkspaces ({
  onClose,
}: {
  onClose: () => void;
}) {
  const [open, setOpen] = React.useState(false);
  const { t } = useTranslation();
  const userWorkspaceInfo = useUserWorkspaceInfo();
  const currentWorkspaceId = useCurrentWorkspaceId();
  const currentUser = useCurrentUser();
  const [changeLoading, setChangeLoading] = React.useState<string | null>(null);
  const {
    onChangeWorkspace: handleSelectedWorkspace,
  } = useAppHandlers();
  const selectedWorkspace = useMemo(() => {
    return userWorkspaceInfo?.workspaces.find((workspace) => workspace.id === currentWorkspaceId);
  }, [currentWorkspaceId, userWorkspaceInfo]);

  const handleOpen = () => {
    setOpen(true);
  };

  const handleClose = useCallback(() => {
    setOpen(false);
  }, []);

  const handleChange = useCallback(async (selectedId: string) => {
    setChangeLoading(selectedId);
    try {
      await handleSelectedWorkspace?.(selectedId);
    } catch (e) {
      notify.error('Failed to change workspace');
    }

    onClose();
    handleClose();
    setChangeLoading(null);
  }, [handleClose, handleSelectedWorkspace, onClose]);

  const triggerNode = useMemo(() => {
    return <div><CurrentWorkspace
      userWorkspaceInfo={userWorkspaceInfo}
      selectedWorkspace={selectedWorkspace}
      onChangeWorkspace={handleChange}
    /></div>;
  }, [handleChange, selectedWorkspace, userWorkspaceInfo]);

  const ref = useRef<HTMLDivElement>(null);

  return (
    <MobileDrawer
      maxHeight={window.innerHeight - 56}
      onOpen={handleOpen}
      onClose={handleClose}
      open={open}
      anchor={'bottom'}
      triggerNode={triggerNode}
    >
      <div
        ref={ref}
        className={'flex flex-col gap-2 w-full overflow-x-hidden  pb-[60px] overflow-y-auto appflowy-scroller'}
      >
        <div className={'flex pt-10 flex-col sticky top-0 bg-bg-body z-[10]'}>
          <div className={'relative p-4'}>
            <IconButton
              color={'inherit'}
              className={'h-6 w-6 absolute font-semibold left-4'}
              onClick={handleClose}
            >
              <CloseIcon className={'h-4 w-4'} />
            </IconButton>
            <div className={'w-full text-center font-medium '}>{t('workspace.menuTitle')}</div>
          </div>
          <div className={'font-medium flex-1 text-base text-text-caption p-4 underline-none'}>{currentUser?.email}</div>
          <Divider className={'w-full'} />
        </div>

        <div
          onTouchMove={e => {
            const el = ref.current as HTMLDivElement;

            if (!el) return;
            if (el.scrollHeight > el.clientHeight) {
              e.stopPropagation();

            }
          }}
          className={'flex flex-col gap-4 p-2'}
        >
          {userWorkspaceInfo?.workspaces.map((workspace) => {
            return <div
              key={workspace.id}
              className={'flex items-center justify-between gap-4 p-2 cursor-pointer'}
              onClick={async () => {
                if (workspace.id === currentWorkspaceId) return;

                void handleChange(workspace.id);
              }}
            >
              <Avatar
                variant={'rounded'}
                className={'rounded-[8px] w-8 h-8 border border-line-divider'} {...getAvatarProps(workspace)} />
              <div className={'flex-1 overflow-hidden'}>
                <div className={'text-text-title truncate font-medium'}>{workspace.name}</div>
                {workspace.memberCount && <div className={'text-text-caption mt-2 text-sm'}>
                  {t('count.members', { count: workspace.memberCount })}
                </div>}
              </div>
              {changeLoading === workspace.id ?
                <CircularProgress size={16} /> : workspace.id === selectedWorkspace?.id &&
                <SelectedSvg className={'w-6 text-fill-default h-6'} />}
            </div>;
          })}
        </div>
        <Divider className={'w-full'} />
      </div>
    </MobileDrawer>
  );
}

export default MobileWorkspaces;