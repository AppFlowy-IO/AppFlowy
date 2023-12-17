import React, { useRef } from 'react';
import CreateNewFolderIcon from '@mui/icons-material/CreateNewFolder';

import { GridNode } from '$app/application/document/document.types';
import { useTranslation } from 'react-i18next';

import Drawer from '$app/components/editor/components/blocks/database/Drawer';

function DatabaseEmpty({ node }: { node: GridNode }) {
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);

  const [open, setOpen] = React.useState(false);

  const toggleDrawer = (open: boolean) => (event: React.KeyboardEvent | React.MouseEvent) => {
    if (
      event &&
      event.type === 'keydown' &&
      ((event as React.KeyboardEvent).key === 'Tab' || (event as React.KeyboardEvent).key === 'Shift')
    ) {
      return;
    }

    if (event?.type === 'click') {
      event.stopPropagation();
    }

    setOpen(open);
  };

  return (
    <div
      ref={ref}
      onClick={toggleDrawer(false)}
      className='relative flex w-full flex-1 flex-col items-center justify-center text-text-caption'
    >
      <CreateNewFolderIcon className={'h-10 w-10'} />
      <div className={'mb-2 text-base'}>{t('document.plugins.database.noDataSource')}</div>
      <div>
        <span onClick={toggleDrawer(true)} className={'mx-2 cursor-pointer underline'}>
          {t('document.plugins.database.selectADataSource')}
        </span>
        {t('document.plugins.database.toContinue')}
      </div>

      <Drawer toggleDrawer={toggleDrawer} open={open} node={node} />
    </div>
  );
}

export default React.memo(DatabaseEmpty);
