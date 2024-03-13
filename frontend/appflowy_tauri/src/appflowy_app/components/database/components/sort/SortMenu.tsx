import { Menu, MenuProps } from '@mui/material';
import { FC, MouseEventHandler, useCallback, useState } from 'react';
import { useViewId } from '$app/hooks';
import { sortService } from '$app/application/database';
import { useDatabaseSorts } from '../../Database.hooks';
import { SortItem } from './SortItem';

import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import SortFieldsMenu from '$app/components/database/components/sort/SortFieldsMenu';
import Button from '@mui/material/Button';

export const SortMenu: FC<MenuProps> = (props) => {
  const { onClose } = props;
  const { t } = useTranslation();
  const viewId = useViewId();
  const sorts = useDatabaseSorts();
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
      <Menu
        onKeyDown={(e) => {
          if (e.key === 'Escape') {
            e.preventDefault();
            e.stopPropagation();
            props.onClose?.({}, 'escapeKeyDown');
          }
        }}
        keepMounted={false}
        MenuListProps={{
          className: 'py-1  w-[360px]',
        }}
        {...props}
        onClose={onClose}
      >
        <div className={'flex max-h-[300px] w-full flex-col overflow-y-auto'}>
          <div className={'mb-1 px-1'}>
            {sorts.map((sort) => (
              <SortItem key={sort.id} className='m-2' sort={sort} />
            ))}
          </div>

          <div className={'mx-2 flex flex-col'}>
            <Button
              onClick={handleClick}
              className={'justify-start px-1.5'}
              variant={'text'}
              color={'inherit'}
              startIcon={<AddSvg />}
            >
              {t('grid.sort.addSort')}
            </Button>
            <Button
              onClick={deleteAllSorts}
              className={'justify-start px-1.5'}
              variant={'text'}
              color={'inherit'}
              startIcon={<DeleteSvg />}
            >
              {t('grid.sort.deleteAllSorts')}
            </Button>
          </div>
        </div>
      </Menu>

      <SortFieldsMenu
        open={openFieldListMenu}
        anchorEl={anchorEl}
        onClose={() => {
          setAnchorEl(null);
        }}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'left',
        }}
      />
    </>
  );
};
