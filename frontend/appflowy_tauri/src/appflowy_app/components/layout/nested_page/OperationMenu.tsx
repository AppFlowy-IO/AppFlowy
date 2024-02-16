import React, { ReactNode, useCallback, useMemo, useState } from 'react';
import { IconButton } from '@mui/material';
import Popover from '@mui/material/Popover';
import KeyboardNavigation from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import Tooltip from '@mui/material/Tooltip';

function OperationMenu({
  options,
  onConfirm,
  isHovering,
  setHovering,
  children,
  tooltip,
  onKeyDown,
}: {
  isHovering: boolean;
  setHovering: (hovering: boolean) => void;
  options: {
    key: string;
    title: string;
    icon: React.ReactNode;
    caption?: string;
  }[];
  children: React.ReactNode;
  onConfirm: (key: string) => void;
  tooltip: string;
  onKeyDown?: (e: KeyboardEvent) => void;
}) {
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const renderItem = useCallback((title: string, icon: ReactNode, caption?: string) => {
    return (
      <div className={'flex w-full items-center justify-between gap-2 px-1 font-medium'}>
        {icon}
        <div className={'flex-1'}>{title}</div>
        <div className={'text-right text-text-caption'}>{caption || ''}</div>
      </div>
    );
  }, []);

  const handleClose = useCallback(() => {
    setAnchorEl(null);
    setHovering(false);
  }, [setHovering]);

  const optionList = useMemo(() => {
    return options.map((option) => {
      return {
        key: option.key,
        content: renderItem(option.title, option.icon, option.caption),
      };
    });
  }, [options, renderItem]);

  const open = Boolean(anchorEl);

  const handleConfirm = useCallback(
    (key: string) => {
      onConfirm(key);
      handleClose();
    },
    [handleClose, onConfirm]
  );

  return (
    <>
      <Tooltip disableInteractive={true} title={tooltip}>
        <IconButton
          size={'small'}
          onClick={(e) => {
            setAnchorEl(e.currentTarget);
          }}
          className={`${!isHovering ? 'invisible' : ''} text-icon-primary`}
        >
          {children}
        </IconButton>
      </Tooltip>

      <Popover
        onClose={handleClose}
        open={open}
        anchorEl={anchorEl}
        disableRestoreFocus={true}
        keepMounted={false}
        PaperProps={{
          className: 'py-2',
        }}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'left',
        }}
      >
        <KeyboardNavigation
          onKeyDown={onKeyDown}
          onEscape={handleClose}
          options={optionList}
          onConfirm={handleConfirm}
        />
      </Popover>
    </>
  );
}

export default OperationMenu;
