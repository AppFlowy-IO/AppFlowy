import { FC, MouseEventHandler, useCallback, useRef, useState } from 'react';
import { IconButton } from '@mui/material';
import { ReactComponent as DetailsSvg } from '$app/assets/details.svg';
import { SelectOption } from '../../../../application';
import { SelectOptionMenu } from '../SelectOptionMenu';
import { Tag } from '../Tag';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';

export interface SelectOptionItemProps {
  option: SelectOption;
  fieldId: string;
  isSelected?: boolean;
  onSelectOption?: (optionId: string) => void;
}

export const SelectOptionItem: FC<SelectOptionItemProps> = ({ isSelected, fieldId, option }) => {
  const [open, setOpen] = useState(false);
  const anchorEl = useRef<HTMLButtonElement | null>(null);
  const [hovered, setHovered] = useState(false);
  const handleClick = useCallback<MouseEventHandler<HTMLButtonElement>>((event) => {
    event.stopPropagation();
    anchorEl.current = event.target as HTMLButtonElement;
    setOpen(true);
  }, []);

  return (
    <div
      className={'flex w-full items-center justify-between'}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <div className='flex-1'>
        <Tag key={option.id} size='small' color={option.color} label={option.name} />
      </div>
      {isSelected && !hovered && <SelectCheckSvg />}
      {hovered && (
        <IconButton onClick={handleClick}>
          <DetailsSvg className='text-base' />
        </IconButton>
      )}

      {open && (
        <SelectOptionMenu
          fieldId={fieldId}
          option={option}
          MenuProps={{
            open,
            anchorEl: anchorEl.current,
            onClose: () => setOpen(false),
          }}
        />
      )}
    </div>
  );
};
