import { FC, useCallback, useMemo, useState } from 'react';
import { MenuProps, Menu } from '@mui/material';

import { SelectField, SelectCell as SelectCellType } from '../../application';
import { Tag } from '../field_types/select/Tag';

import SelectCellActions from '$app/components/database/components/field_types/select/select_cell_actions/SelectCellActions';

const menuProps: Partial<MenuProps> = {
  classes: {
    list: 'py-5',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
};

export const SelectCell: FC<{
  field: SelectField;
  cell?: SelectCellType;
}> = ({ field, cell }) => {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const selectedIds = useMemo(() => cell?.data?.selectedOptionIds ?? [], [cell]);
  const open = Boolean(anchorEl);
  const handleClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const renderSelectedOptions = useCallback(
    (selected: string[]) =>
      selected
        .map((id) => field.typeOption.options?.find((option) => option.id === id))
        .map((option) => option && <Tag key={option.id} size='small' color={option.color} label={option.name} />),
    [field]
  );

  return (
    <div className={'relative w-full'}>
      <div
        onClick={(e) => {
          setAnchorEl(e.currentTarget);
        }}
        className={'absolute left-0 top-0 flex h-full w-full items-center gap-2 px-4 py-1'}
      >
        {renderSelectedOptions(selectedIds)}
      </div>
      {open && cell ? (
        <Menu
          keepMounted={false}
          className='h-full w-full'
          open={open}
          anchorEl={anchorEl}
          {...menuProps}
          onClose={handleClose}
        >
          <SelectCellActions field={field} cell={cell} />
        </Menu>
      ) : null}
    </div>
  );
};
