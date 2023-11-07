import React, { useCallback } from 'react';
import { MenuList, MenuItem, Icon } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as UpSvg } from '$app/assets/up.svg';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ReactComponent as DelSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { rowService } from '$app/components/database/application';
import { useViewId } from '@/appflowy_app/hooks/ViewId.hooks';

interface Props {
  rowId: string;
  getPrevRowId: (id: string) => string | null;
  onClickItem: (label: string) => void;
}

interface Option {
  label: string;
  icon: JSX.Element;
  onClick: () => void;
  divider?: boolean;
}

function GridCellRowMenu({ rowId, getPrevRowId, onClickItem }: Props) {
  const viewId = useViewId();

  const { t } = useTranslation();

  const handleInsertRecordBelow = useCallback(() => {
    void rowService.createRow(viewId, {
      startRowId: rowId,
    });
  }, [viewId, rowId]);

  const handleInsertRecordAbove = useCallback(() => {
    const prevRowId = getPrevRowId(rowId);

    void rowService.createRow(viewId, {
      startRowId: prevRowId || undefined,
    });
  }, [getPrevRowId, rowId, viewId]);

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
    <MenuList>
      {options.map((option) => (
        <div className={'w-full'} key={option.label}>
          {option.divider && <div className='mx-2 my-1.5 h-[1px] bg-line-divider' />}
          <MenuItem
            onClick={() => {
              option.onClick();
              onClickItem(option.label);
            }}
          >
            <Icon className='mr-2'>{option.icon}</Icon>
            {option.label}
          </MenuItem>
        </div>
      ))}
    </MenuList>
  );
}

export default GridCellRowMenu;
