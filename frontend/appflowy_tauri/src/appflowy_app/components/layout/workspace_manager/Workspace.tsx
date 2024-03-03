import React, { useState } from 'react';
import { WorkspaceItem } from '$app_reducers/workspace/slice';
import NestedViews from '$app/components/layout/workspace_manager/NestedPages';
import { useLoadWorkspace, useWorkspaceActions } from '$app/components/layout/workspace_manager/Workspace.hooks';
import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddIcon } from '$app/assets/add.svg';
import { IconButton } from '@mui/material';
import Tooltip from '@mui/material/Tooltip';

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
            <Typography className={'rounded px-2 py-1 text-xs font-medium hover:bg-fill-list-active'}>
              {t('sideBar.personal')}
            </Typography>
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
