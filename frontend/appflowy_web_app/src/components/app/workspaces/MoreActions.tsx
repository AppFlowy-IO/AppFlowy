import React from 'react';
import { ReactComponent as MoreSvg } from '@/assets/more.svg';
import { IconButton } from '@mui/material';
import { Workspace } from '@/application/types';
import { Popover } from '@/components/_shared/popover';
import LeaveWorkspace from '@/components/app/workspaces/LeaveWorkspace';
import { useCurrentUser } from '@/components/main/app.hooks';
import DeleteWorkspace from '@/components/app/workspaces/DeleteWorkspace';
import RenameWorkspace from '@/components/app/workspaces/RenameWorkspace';

function MoreActions ({ workspace, onUpdated }: {
  workspace: Workspace;
  onUpdated: (name: string) => void;
}) {
  const ref = React.useRef<HTMLButtonElement | null>(null);
  const [open, setOpen] = React.useState(false);
  const currentUser = useCurrentUser();
  const isOwner = workspace.owner?.uid.toString() === currentUser?.uid.toString();

  return (
    <>
      <IconButton
        onClick={e => {
          e.stopPropagation();
          setOpen(true);
        }}
        ref={ref}
        size={'small'}
        className={'p-1'}
        color={'inherit'}
      >
        <MoreSvg className={'w-4 h-4'} />
      </IconButton>
      <Popover
        slotProps={{
          paper: {
            className: 'p-2 w-[260px]',
          },
        }}
        onClick={e => {
          e.stopPropagation();
        }}
        open={open}
        onClose={() => setOpen(false)}
        anchorEl={ref.current}
      >
        {isOwner ? (
          <div className={'flex flex-col gap-2'}>
            <RenameWorkspace
              onUpdated={(name: string) => {
                onUpdated(name);
                setOpen(false);
              }}
              workspace={workspace}
            />
            <DeleteWorkspace
              name={workspace.name}
              workspaceId={workspace.id}
            />

          </div>
        ) : <LeaveWorkspace
          workspaceId={workspace.id}
        />}
      </Popover>
    </>
  );
}

export default MoreActions;