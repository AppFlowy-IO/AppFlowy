import { UserWorkspaceInfo, Workspace } from '@/application/types';
import { getAvatarProps } from '@/components/app/workspaces/utils';
import { Avatar } from '@mui/material';
import React from 'react';
import { ReactComponent as AppFlowyLogo } from '@/assets/appflowy.svg';

function CurrentWorkspace ({
  userWorkspaceInfo,
  selectedWorkspace,
  onChangeWorkspace,
}: {
  userWorkspaceInfo?: UserWorkspaceInfo;
  selectedWorkspace?: Workspace;
  onChangeWorkspace: (selectedId: string) => void;
}) {

  if (!userWorkspaceInfo || !selectedWorkspace) {
    return <div
      className={'flex p-2 cursor-pointer items-center gap-1 text-text-title'}
      onClick={async () => {
        const selectedId = userWorkspaceInfo?.selectedWorkspace?.id || userWorkspaceInfo?.workspaces[0]?.id;

        if (!selectedId) return;

        void onChangeWorkspace(selectedId);
      }}
    >
      <AppFlowyLogo className={'w-[88px]'} />
    </div>;
  }

  return <div className={'flex items-center gap-2'}>
    <Avatar
      variant={'rounded'}
      className={`w-8 h-8 flex items-center justify-center border p-1 border-line-divider rounded-[8px] ${selectedWorkspace.icon ? 'bg-transparent' : ''}`}
      {...getAvatarProps(selectedWorkspace)}
    />
    <div className={'text-text-title flex-1 truncate font-semibold'}>{selectedWorkspace.name}</div>
  </div>;
}

export default CurrentWorkspace;