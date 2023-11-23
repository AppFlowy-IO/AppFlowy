import { Menu, MenuItem, MenuProps } from '@mui/material';
import { FC, MouseEventHandler, useCallback, useState } from 'react';
import { useViewId } from '$app/hooks';
import { sortService } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { SortItem } from './SortItem';

import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import SortFieldsMenu from '$app/components/database/components/sort/SortFieldsMenu';

export const SortMenu: FC<MenuProps> = (props) => {
  const { onClose } = props;
  const { t } = useTranslation();
  const viewId = useViewId();
  const { sorts } = useDatabase();
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const openFieldListMenu = Boolean(anchorEl);
  const handleClick = useCallback<MouseEventHandler<HTMLElement>>((event) => {
    setAnchorEl(event.currentTarget);
  }, []);

  const deleteAllSorts = useCallback(() => {
    void sortService.deleteAllSorts(viewId);
    onClose?.({}, 'backdropClick');
  }, [viewId, onClose]);

  return (
    <>
      <Menu keepMounted={false} {...props} onClose={onClose}>
        <div className={'max-h-[300px] overflow-y-auto p-2'}>
          <div className={'mb-2 px-4'}>
            {sorts.map((sort) => (
              <SortItem key={sort.id} className='m-2' sort={sort} />
            ))}
          </div>

          <MenuItem onClick={handleClick}>
            <AddSvg className={'mr-1 h-5 w-5'} />
            {t('grid.sort.addSort')}
          </MenuItem>
          <MenuItem onClick={deleteAllSorts}>
            <DeleteSvg className={'mr-1 h-5 w-5'} />
            {t('grid.sort.deleteAllSorts')}
          </MenuItem>
        </div>
      </Menu>

      <SortFieldsMenu
        open={openFieldListMenu}
        anchorEl={anchorEl}
        onClose={() => {
          setAnchorEl(null);
        }}
      />
    </>
  );
};
