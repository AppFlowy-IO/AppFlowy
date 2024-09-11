import { OutlineDrawer } from '@/components/_shared/outline';
import Outline from '@/components/_shared/outline/Outline';
import { AppContext, useAppOutline, useAppViewId } from '@/components/app/app.hooks';
import { Button, Divider } from '@mui/material';
import React, { useContext } from 'react';
import { Favorite } from '@/components/app/favorite';
import { useTranslation } from 'react-i18next';
import Trash from 'src/components/app/trash/Trash';
import { ReactComponent as TemplateIcon } from '@/assets/template.svg';

interface SideBarProps {
  drawerWidth: number;
  drawerOpened: boolean;
  toggleOpenDrawer: (status: boolean) => void;
  onResizeDrawerWidth: (width: number) => void;
}

function SideBar ({
  drawerWidth,
  drawerOpened,
  toggleOpenDrawer,
  onResizeDrawerWidth,
}: SideBarProps) {
  const outline = useAppOutline();
  const { t } = useTranslation();
  const viewId = useAppViewId();
  const navigateToView = useContext(AppContext)?.toView;

  return (
    <OutlineDrawer
      onResizeWidth={onResizeDrawerWidth}
      width={drawerWidth}
      open={drawerOpened}
      onClose={() => toggleOpenDrawer(false)}
    >
      <div className={'flex w-full flex-1 flex-col'}>
        <Favorite />
        <Outline
          variant={'app'}
          navigateToView={navigateToView}
          selectedViewId={viewId}
          width={drawerWidth}
          outline={outline}
        />
        <div
          className={'flex border-t border-line-divider py-4 px-4 gap-1 justify-between items-center sticky bottom-[51.5px] bg-bg-body'}
        >
          <Button
            startIcon={<TemplateIcon className={'h-5 w-5'} />}
            size={'small'}
            onClick={() => {
              window.open('https://appflowy.io/templates', '_blank');
            }}
            variant={'text'}
            className={'flex-1'}
            color={'inherit'}
          >
            {t('template.label')}
          </Button>
          <Divider orientation={'vertical'} flexItem />
          <Trash />
        </div>
      </div>
    </OutlineDrawer>
  );
}

export default SideBar;