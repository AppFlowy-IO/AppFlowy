import { FC, MouseEventHandler, useCallback, useRef, useState } from 'react';
import { IconButton } from '@mui/material';
import { ReactComponent as DetailsSvg } from '$app/assets/details.svg';
import { SelectOption } from '../../../application';
import { SelectOptionMenu } from './SelectOptionMenu';
import { Tag } from './Tag';

export interface SelectOptionItemProps {
  option: SelectOption;
}

export const SelectOptionItem: FC<SelectOptionItemProps> = ({
  option,
}) => {
  const [open, setOpen] = useState(false);
  const anchorEl = useRef<HTMLButtonElement | null>(null);

  const handleClick = useCallback<MouseEventHandler<HTMLButtonElement>>((event) => {
    event.stopPropagation();
    anchorEl.current = event.target as HTMLButtonElement;
    setOpen(true);
  }, []);

  return (
    <>
      <div className="flex-1">
        <Tag
          key={option.id}
          size="small"
          color={option.color}
          label={option.name}
        />
      </div>
      <IconButton onClick={handleClick}>
        <DetailsSvg className="text-base" />
      </IconButton>
      {open && (
        <SelectOptionMenu
          open={open}
          option={option}
          MenuProps={{
            anchorEl: anchorEl.current,
            onClose: () => setOpen(false),
          }}
        />
      )}
    </>
  );
};
