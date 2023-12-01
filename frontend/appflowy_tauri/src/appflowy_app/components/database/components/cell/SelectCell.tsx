import { FC, useCallback, useMemo, useState, Suspense, lazy } from 'react';
import { MenuProps, Menu } from '@mui/material';
import { SelectField, SelectCell as SelectCellType, SelectTypeOption } from '../../application';
import { Tag } from '../field_types/select/Tag';
import { useTypeOption } from '$app/components/database';

const SelectCellActions = lazy(
  () => import('$app/components/database/components/field_types/select/select_cell_actions/SelectCellActions')
);
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
  cell: SelectCellType;
  placeholder?: string;
}> = ({ field, cell, placeholder }) => {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const selectedIds = useMemo(() => cell.data?.selectedOptionIds ?? [], [cell]);
  const open = Boolean(anchorEl);
  const handleClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const typeOption = useTypeOption<SelectTypeOption>(field.id);

  const renderSelectedOptions = useCallback(
    (selected: string[]) =>
      selected
        .map((id) => typeOption.options?.find((option) => option.id === id))
        .map((option) => option && <Tag key={option.id} size='small' color={option.color} label={option.name} />),
    [typeOption]
  );

  return (
    <div className={'relative w-full'}>
      <div
        onClick={(e) => {
          setAnchorEl(e.currentTarget);
        }}
        className={'flex h-full w-full cursor-pointer items-center gap-2 overflow-x-hidden px-2 py-1'}
      >
        {selectedIds.length === 0 ? (
          <div className={'text-sm text-text-placeholder'}>{placeholder}</div>
        ) : (
          renderSelectedOptions(selectedIds)
        )}
      </div>
      <Suspense>
        {open ? (
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
      </Suspense>
    </div>
  );
};
