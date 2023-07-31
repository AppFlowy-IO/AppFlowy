import React, { useState } from 'react';
import MoreButton from '$app/components/layout/WorkspaceManager/MoreButton';
import MenuItem from '@mui/material/MenuItem';
import { WorkspaceItem } from '$app_reducers/workspace/slice';

function WorkspaceTitle({
  workspace,
  openWorkspace,
  onDelete,
}: {
  openWorkspace: () => void;
  onDelete: (id: string) => void;
  workspace: WorkspaceItem;
}) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <MenuItem
      onClick={() => openWorkspace()}
      onMouseEnter={() => {
        setIsHovered(true);
      }}
      onMouseLeave={() => {
        setIsHovered(false);
      }}
      className={'hover:bg-fill-list-active'}
    >
      <div className={'flex w-[100%] items-center justify-between'}>
        <div className={'flex-1 font-bold text-text-caption'}>{workspace.name}</div>
        <div className='flex h-[23px] w-auto items-center justify-end'>
          <MoreButton workspace={workspace} isHovered={isHovered} onDelete={onDelete} />
        </div>
      </div>
    </MenuItem>
  );
}

export default WorkspaceTitle;
