import React, { useCallback } from 'react';
import { Button, IconButton } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { createGrid } from '$app/components/editor/components/blocks/database/utils';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import { useEditorId } from '$app/components/editor/Editor.hooks';
import { GridNode } from '$app/application/document/document.types';
import { ReactComponent as CloseSvg } from '$app/assets/close.svg';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import DatabaseList from '$app/components/editor/components/blocks/database/DatabaseList';

function Drawer({
  open,
  toggleDrawer,
  node,
}: {
  open: boolean;
  toggleDrawer: (open: boolean) => (e: React.MouseEvent | KeyboardEvent | React.FocusEvent) => void;
  node: GridNode;
}) {
  const editor = useSlateStatic();
  const id = useEditorId();
  const { t } = useTranslation();
  const handleCreateGrid = useCallback(async () => {
    const gridId = await createGrid(id);

    CustomEditor.setGridBlockViewId(editor, node, gridId);
  }, [id, editor, node]);

  return (
    <div
      onClick={(e) => {
        e.stopPropagation();
      }}
      className={'absolute right-0 top-0 h-full transform overflow-hidden'}
      style={{
        width: open ? '250px' : '0px',
        transition: 'width 0.3s ease-in-out',
      }}
      onMouseDown={(e) => {
        const isInput = (e.target as HTMLElement).closest('input');

        if (isInput) return;
        e.stopPropagation();
        e.preventDefault();
      }}
    >
      <div className={'flex h-full w-[250px] flex-col border-l border-line-divider'}>
        <div className={'flex h-[48px] w-full items-center justify-between p-2'}>
          <div className={'px-2 font-medium'}>{t('document.plugins.database.selectDataSource')}</div>
          <IconButton onClick={toggleDrawer(false)}>
            <CloseSvg />
          </IconButton>
        </div>
        <div className={'flex-1 overflow-hidden'}>
          {open && <DatabaseList toggleDrawer={toggleDrawer} node={node} />}
        </div>

        <div
          onClick={handleCreateGrid}
          className={'sticky bottom-0 left-0 h-[48px] w-full border-t border-line-divider p-2'}
        >
          <Button color={'inherit'} className={'w-full justify-start'} startIcon={<AddSvg />}>
            {t('document.plugins.database.newDatabase')}
          </Button>
        </div>
      </div>
    </div>
  );
}

export default Drawer;
