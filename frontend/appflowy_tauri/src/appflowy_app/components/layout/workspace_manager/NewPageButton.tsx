import React from 'react';
import { useTranslation } from 'react-i18next';
import { useWorkspaceActions } from '$app/components/layout/workspace_manager/Workspace.hooks';
import Button from '@mui/material/Button';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';

function NewPageButton({ workspaceId }: { workspaceId: string }) {
  const { t } = useTranslation();
  const { newPage } = useWorkspaceActions(workspaceId);

  return (
    <div className={'flex h-[60px] w-full items-center border-t border-line-divider px-5 py-5'}>
      <Button
        color={'inherit'}
        onClick={newPage}
        startIcon={
          <div className={'rounded-full bg-fill-default'}>
            <div className={'flex h-[18px] w-[18px] items-center justify-center px-0 text-lg text-content-on-fill'}>
              <AddSvg />
            </div>
          </div>
        }
        className={'flex w-full items-center justify-start text-xs hover:bg-transparent hover:text-fill-default'}
      >
        {t('newPageText')}
      </Button>
    </div>
  );
}

export default NewPageButton;
