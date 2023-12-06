import React, { useCallback } from 'react';
import { Icon, Menu, MenuProps } from '@mui/material';
import { ReactComponent as DelSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { useTranslation } from 'react-i18next';
import { rowService } from '$app/components/database/application';
import { useViewId } from '$app/hooks';
import MenuItem from '@mui/material/MenuItem';

interface Props extends MenuProps {
  rowId: string;
  onClose?: () => void;
}
function RecordActions({ anchorEl, open, onClose, rowId }: Props) {
  const viewId = useViewId();
  const { t } = useTranslation();

  const handleDelRow = useCallback(() => {
    void rowService.deleteRow(viewId, rowId);
  }, [viewId, rowId]);

  const handleDuplicateRow = useCallback(() => {
    void rowService.duplicateRow(viewId, rowId);
  }, [viewId, rowId]);

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
    <Menu anchorEl={anchorEl} open={open} onClose={onClose}>
      {menuOptions.map((option) => (
        <MenuItem
          key={option.label}
          onClick={() => {
            option.onClick();
            onClose?.();
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
