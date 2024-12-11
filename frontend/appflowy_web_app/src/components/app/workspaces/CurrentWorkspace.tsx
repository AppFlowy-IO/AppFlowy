import { UserWorkspaceInfo, Workspace } from '@/application/types';
import { getAvatarProps } from '@/components/app/workspaces/utils';
import { Avatar } from '@mui/material';
import React from 'react';
import { ReactComponent as AppFlowyLogo } from '@/assets/appflowy.svg';

function CurrentWorkspace({
  userWorkspaceInfo,
  selectedWorkspace,
  onChangeWorkspace,
  avatarSize = 32,
}: {
  userWorkspaceInfo?: UserWorkspaceInfo;
  selectedWorkspace?: Workspace;
  onChangeWorkspace: (selectedId: string) => void;
  avatarSize?: number;
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
      <AppFlowyLogo className={'w-[88px]'}/>
    </div>;
  }

  return <div className={'flex items-center gap-2'}>
    <Avatar
      variant={'rounded'}
      className={`flex items-center justify-center border-none p-1 border-line-divider rounded-[8px] ${selectedWorkspace.icon ? 'bg-transparent' : ''}`}
      {...getAvatarProps(selectedWorkspace)}
      style={{
        width: avatarSize,
        height: avatarSize,
        fontSize: avatarSize / 1.2,
      }}
    />
    <div className={'text-text-title flex-1 truncate font-medium'}>{selectedWorkspace.name}</div>
  </div>;
}

export default CurrentWorkspace;