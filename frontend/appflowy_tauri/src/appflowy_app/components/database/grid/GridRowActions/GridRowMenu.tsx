import React, { useCallback } from 'react';
import { ReactComponent as UpSvg } from '$app/assets/up.svg';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ReactComponent as DelSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { rowService } from '$app/components/database/application';
import { Icon, MenuItem, MenuList } from '@mui/material';
import { OrderObjectPositionTypePB } from '@/services/backend';

interface Option {
  label: string;
  icon: JSX.Element;
  onClick: () => void;
  divider?: boolean;
}

interface Props extends PopoverProps {
  rowId: string;
}

function GridRowMenu({ rowId, ...props }: Props) {
  const viewId = useViewId();

  const { t } = useTranslation();

  const handleInsertRecordBelow = useCallback(() => {
    void rowService.createRow(viewId, {
      position: OrderObjectPositionTypePB.After,
      rowId: rowId,
    });
  }, [viewId, rowId]);

  const handleInsertRecordAbove = useCallback(() => {
    void rowService.createRow(viewId, {
      position: OrderObjectPositionTypePB.Before,
      rowId: rowId,
    });
  }, [rowId, viewId]);

  const handleDelRow = useCallback(() => {
    void rowService.deleteRow(viewId, rowId);
  }, [viewId, rowId]);

  const handleDuplicateRow = useCallback(() => {
    void rowService.duplicateRow(viewId, rowId);
  }, [viewId, rowId]);

  const options: Option[] = [
    {
      label: t('grid.row.insertRecordAbove'),
      icon: <UpSvg />,
      onClick: handleInsertRecordAbove,
    },
    {
      label: t('grid.row.insertRecordBelow'),
      icon: <AddSvg />,
      onClick: handleInsertRecordBelow,
    },
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
    <Popover
      disableRestoreFocus={true}
      keepMounted={false}
      anchorReference={'anchorPosition'}
      transformOrigin={{ vertical: 'top', horizontal: 'left' }}
      {...props}
    >
      <MenuList>
        {options.map((option) => (
          <div className={'w-full'} key={option.label}>
            {option.divider && <div className='mx-2 my-1.5 h-[1px] bg-line-divider' />}
            <MenuItem
              onClick={() => {
                option.onClick();
                props.onClose?.({}, 'backdropClick');
              }}
            >
              <Icon className='mr-2'>{option.icon}</Icon>
              {option.label}
            </MenuItem>
          </div>
        ))}
      </MenuList>
    </Popover>
  );
}

export default GridRowMenu;
