import { FC, useCallback, useMemo, useState, Suspense, lazy } from 'react';
import { MenuProps } from '@mui/material';
import { SelectField, SelectCell as SelectCellType, SelectTypeOption } from '$app/application/database';
import { Tag } from '../field_types/select/Tag';
import { useTypeOption } from '$app/components/database';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import Popover from '@mui/material/Popover';

const initialAnchorOrigin: PopoverOrigin = {
  vertical: 'bottom',
  horizontal: 'center',
};

const initialTransformOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'center',
};
const SelectCellActions = lazy(
  () => import('$app/components/database/components/field_types/select/select_cell_actions/SelectCellActions')
);
const menuProps: Partial<MenuProps> = {
  classes: {
    list: 'py-5',
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

  const { paperHeight, paperWidth, transformOrigin, anchorOrigin, isEntered } = usePopoverAutoPosition({
    initialPaperWidth: 369,
    initialPaperHeight: 400,
    anchorEl,
    initialAnchorOrigin,
    initialTransformOrigin,
    open,
  });

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
          <Popover
            keepMounted={false}
            disableRestoreFocus={true}
            className='h-full w-full'
            open={open && isEntered}
            anchorEl={anchorEl}
            {...menuProps}
            transformOrigin={transformOrigin}
            anchorOrigin={anchorOrigin}
            onClose={handleClose}
            PaperProps={{
              className: 'flex h-full flex-col py-4 overflow-hidden',
              style: {
                maxHeight: paperHeight,
                maxWidth: paperWidth,
                height: 'auto',
              },
            }}
            onMouseDown={(e) => {
              const isInput = (e.target as Element).closest('input');

              if (isInput) return;

              e.preventDefault();
              e.stopPropagation();
            }}
          >
            <SelectCellActions onClose={handleClose} field={field} cell={cell} />
          </Popover>
        ) : null}
      </Suspense>
    </div>
  );
};
