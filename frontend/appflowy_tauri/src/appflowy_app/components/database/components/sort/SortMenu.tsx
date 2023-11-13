import { Menu, MenuItem, MenuProps } from '@mui/material';
import { FC, MouseEventHandler, useCallback, useState, MouseEvent } from 'react';
import { useViewId } from '$app/hooks';
import { Field, sortService } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { FieldsMenu } from '../field';
import { SortItem } from './SortItem';
import { SortConditionPB } from '@/services/backend';

export const SortMenu: FC<MenuProps> = (props) => {
  const { onClose } = props;

  const viewId = useViewId();
  const { sorts } = useDatabase();
  const [ anchorEl, setAnchorEl ] = useState<HTMLElement | null>(null);

  const handleClick = useCallback<MouseEventHandler<HTMLElement>>((event) => {
    setAnchorEl(event.currentTarget);
  }, []);

  const handleClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const deleteAllSorts = useCallback(() => {
    void sortService.deleteAllSorts(viewId);
    onClose?.({}, 'backdropClick');
  }, [viewId, onClose]);

  const addSort = useCallback((event: MouseEvent, field: Field) => {
    void sortService.insertSort(viewId, {
      fieldId: field.id,
      fieldType: field.type,
      condition: SortConditionPB.Ascending,
    });
  }, [viewId]);

  return (
    <>
      <Menu {...props}>
        {sorts.map(sort => (
          <SortItem key={sort.id} className="mx-2" sort={sort} />
        ))}
        <MenuItem onClick={handleClick}>
          Add sort
        </MenuItem>
        <MenuItem onClick={deleteAllSorts}>
          Delete sort
        </MenuItem>
      </Menu>
      <FieldsMenu
        open={anchorEl !== null}
        anchorEl={anchorEl}
        onClose={handleClose}
        onMenuItemClick={addSort}
      />
    </>
  );
};
