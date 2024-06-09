import React, { useCallback } from 'react';
import { Icon, Menu, MenuProps } from '@mui/material';
import { ReactComponent as DelSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { useTranslation } from 'react-i18next';
import { rowService } from '$app/application/database';
import { useViewId } from '$app/hooks';
import MenuItem from '@mui/material/MenuItem';

interface Props extends MenuProps {
  rowId: string;
  onEscape?: () => void;
  onClose?: () => void;
}
function RecordActions({ anchorEl, open, onEscape, onClose, rowId }: Props) {
  const viewId = useViewId();
  const { t } = useTranslation();

  const handleDelRow = useCallback(() => {
    void rowService.deleteRow(viewId, rowId);
    onEscape?.();
  }, [viewId, rowId, onEscape]);

  const handleDuplicateRow = useCallback(() => {
    void rowService.duplicateRow(viewId, rowId);
    onEscape?.();
  }, [viewId, rowId, onEscape]);

  const menuOptions = [
    {
      label: t('grid.row.duplicate'),
      icon: <CopySvg />,
      onClick: handleDuplicateRow,
    },

    {
      label: t('grid.row.delete'),
      icon: <DelSvg />,
      onClick: handleDelRow,
      divider: true,
    },
  ];

  return (
    <Menu anchorEl={anchorEl} disableRestoreFocus={true} open={open} onClose={onClose}>
      {menuOptions.map((option) => (
        <MenuItem
          key={option.label}
          onClick={() => {
            option.onClick();
            onClose?.();
            onEscape?.();
          }}
        >
          <Icon className='mr-2'>{option.icon}</Icon>
          {option.label}
        </MenuItem>
      ))}
    </Menu>
  );
}

export default RecordActions;
