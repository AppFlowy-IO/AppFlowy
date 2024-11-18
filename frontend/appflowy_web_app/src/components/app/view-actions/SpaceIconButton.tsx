import SpaceIcon from '@/components/_shared/breadcrumb/SpaceIcon';
import ChangeIconPopover from '@/components/_shared/view-icon/ChangeIconPopover';
import { Avatar } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React from 'react';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';

const popoverProps: Partial<PopoverProps> = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'center',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
};

function SpaceIconButton ({
  spaceIcon,
  spaceIconColor,
  spaceName,
  onSelectSpaceIcon,
  onSelectSpaceIconColor,
  size,
}: {
  spaceIconColor?: string;
  spaceIcon?: string;
  spaceName: string;
  onSelectSpaceIcon: (icon: string) => void;
  onSelectSpaceIconColor: (color: string) => void;
  size?: number;
}) {
  const [spaceIconEditing, setSpaceIconEditing] = React.useState<boolean>(false);
  const [iconAnchorEl, setIconAnchorEl] = React.useState<null | HTMLElement>(null);

  return (

    <>
      <Avatar
        variant={'rounded'}
        className={`${size ? `w-[${size}px] h-[${size}px]` : 'w-10 h-10'} rounded-[30%]`}
        onMouseEnter={() => setSpaceIconEditing(true)}
        onMouseLeave={() => setSpaceIconEditing(false)}
        onClick={e => {
          setSpaceIconEditing(false);
          setIconAnchorEl(e.currentTarget);
        }}
      >
        <SpaceIcon
          bgColor={spaceIconColor}
          value={spaceIcon || ''}
          className={'rounded-full w-full h-full p-0.5'}
          char={spaceIcon ? undefined : spaceName.slice(0, 1)}
        />
        {spaceIconEditing &&
          <div className={'absolute cursor-pointer inset-0 bg-black bg-opacity-30 rounded-[8px]'}>
            <div className={'flex items-center text-white justify-center w-full h-full'}>
              <EditIcon />
            </div>
          </div>
        }
      </Avatar>
      {Boolean(iconAnchorEl) && <ChangeIconPopover
        popoverProps={popoverProps}
        defaultType={'icon'}
        emojiEnabled={false}
        open={Boolean(iconAnchorEl)}
        anchorEl={iconAnchorEl}
        onClose={() => {
          setIconAnchorEl(null);

        }}
        onSelectIcon={({ value, color }) => {
          onSelectSpaceIcon(value);
          onSelectSpaceIconColor(color || '');
        }}
      />}
    </>
  );
}

export default SpaceIconButton;