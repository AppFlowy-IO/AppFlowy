import { MobileDrawer } from '@/components/_shared/mobile-drawer';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useCurrentWorkspaceId, useUserWorkspaceInfo } from '@/components/app/app.hooks';
import CurrentWorkspace from '@/components/app/workspaces/CurrentWorkspace';
import WorkspaceList from '@/components/app/workspaces/WorkspaceList';
import { useCurrentUser } from '@/components/main/app.hooks';
import { Divider, IconButton } from '@mui/material';
import React, { useCallback, useMemo, useRef } from 'react';
import { useTranslation } from 'react-i18next';
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
          className={'flex flex-col text-lg gap-4 p-2'}
        >
          {open && <WorkspaceList
            defaultWorkspaces={userWorkspaceInfo?.workspaces}
            currentWorkspaceId={currentWorkspaceId}
            onChange={handleChange}
            changeLoading={changeLoading || undefined}
            showActions={false}
          />}

        </div>
        <Divider className={'w-full'} />
      </div>
    </MobileDrawer>
  );
}

export default MobileWorkspaces;