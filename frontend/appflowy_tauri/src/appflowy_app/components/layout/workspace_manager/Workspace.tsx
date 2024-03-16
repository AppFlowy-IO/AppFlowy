import React, { useState } from 'react';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import NestedViews from '$app/components/layout/workspace_manager/NestedPages';
import { useLoadWorkspace, useWorkspaceActions } from '$app/components/layout/workspace_manager/Workspace.hooks';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddIcon } from '$app/assets/add.svg';
import { IconButton } from '@mui/material';
import Tooltip from '@mui/material/Tooltip';
import { WorkplaceAvatar } from '$app/components/_shared/avatar';

function Workspace({ workspace, opened }: { workspace: WorkspaceItem; opened: boolean }) {
  useLoadWorkspace(workspace);
  const { t } = useTranslation();
  const { newPage } = useWorkspaceActions(workspace.id);
  const [showPages, setShowPages] = useState(true);
  const [showAdd, setShowAdd] = useState(false);

  return (
    <>
      <div
        className={'w-full'}
        style={{
          height: opened ? '100%' : 0,
          overflow: 'hidden',
          transition: 'height 0.2s ease-in-out',
        }}
      >
        <div
          onClick={(e) => {
            e.stopPropagation();
            e.preventDefault();
            setShowPages((prev) => {
              return !prev;
            });
          }}
          onMouseEnter={() => {
            setShowAdd(true);
          }}
          onMouseLeave={() => {
            setShowAdd(false);
          }}
          className={'mt-2 flex h-[22px] w-full  cursor-pointer select-none items-center justify-between px-4'}
        >
          <Tooltip disableInteractive={true} placement={'top-start'} title={t('sideBar.clickToHidePersonal')}>
            <div className={'flex items-center gap-2 rounded px-2 py-1 text-xs font-medium hover:bg-fill-list-active'}>
              {!workspace.name ? (
                t('sideBar.personal')
              ) : (
                <>
                  <WorkplaceAvatar
                    icon={workspace.icon}
                    workplaceName={workspace.name}
                    width={18}
                    height={18}
                    className={'text-[70%]'}
                  />
                  {workspace.name}
                </>
              )}
            </div>
          </Tooltip>
          {showAdd && (
            <Tooltip disableInteractive={true} title={t('sideBar.addAPage')}>
              <IconButton
                onClick={(e) => {
                  e.stopPropagation();
                  void newPage();
                }}
                size={'small'}
              >
                <AddIcon />
              </IconButton>
            </Tooltip>
          )}
        </div>

        <div className={`${showPages ? '' : 'hidden'}`}>
          <NestedViews workspaceId={workspace.id} />
        </div>
      </div>
    </>
  );
}

export default Workspace;
