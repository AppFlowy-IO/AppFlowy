import React, { useMemo } from 'react';
import { ViewLayoutPB } from '@/services/backend';
import { useLoadDatabaseList } from '$app/components/document/_shared/DatabaseList/index.hooks';
import { List } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { BackupTableOutlined } from '@mui/icons-material';
import MenuItem from '@mui/material/MenuItem';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { BlockType } from '$app/interfaces/document';
import AddSvg from '$app/components/_shared/svg/AddSvg';
import Button from '@mui/material/Button';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';

interface Props {
  layout: ViewLayoutPB;
  searchText?: string;
  blockId: string;
  onClose?: () => void;
}

function DatabaseList({ layout, searchText, blockId, onClose }: Props) {
  const { t } = useTranslation();
  const { docId } = useSubscribeDocument();
  const pageController = useMemo(() => new PageController(docId), [docId]);
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();
  const { list } = useLoadDatabaseList({
    searchText: searchText || '',
    layout,
  });

  const renderEmpty = () => {
    return <div className={'p-2 text-text-caption'}>No {layout === ViewLayoutPB.Grid ? 'grid' : 'list'} found</div>;
  };

  const handleReferenceDatabase = (viewId: string) => {
    let blockType;

    switch (layout) {
      case ViewLayoutPB.Grid:
        blockType = BlockType.GridBlock;
        break;
      default:
        break;
    }

    if (blockType === undefined) return;
    onClose?.();
    void dispatch(
      turnToBlockThunk({
        id: blockId,
        controller,
        type: blockType,
        data: {
          viewId,
        },
      })
    );
  };

  const handleCreateNewGrid = async () => {
    const newViewId = await pageController.createPage({
      layout,
      name: t('editor.table'),
    });

    handleReferenceDatabase(newViewId);
  };

  return (
    <div className={'max-h-[360px] w-[200px] p-3'}>
      <div className={'flex items-center justify-center'}>
        <Button
          color='inherit'
          startIcon={
            <i className={'h-8 w-8'}>
              <AddSvg />
            </i>
          }
          onClick={handleCreateNewGrid}
        >
          {t('document.slashMenu.grid.createANewGrid')}
        </Button>
      </div>
      {list.length === 0 ? (
        renderEmpty()
      ) : (
        <List>
          {list.map((item) => (
            <MenuItem onClick={() => handleReferenceDatabase(item.id)} key={item.id}>
              <div className={'mr-2'}>{item.icon?.value || <BackupTableOutlined />}</div>
              {item.name || t('grid.title.placeholder')}
            </MenuItem>
          ))}
        </List>
      )}
    </div>
  );
}

export default DatabaseList;
