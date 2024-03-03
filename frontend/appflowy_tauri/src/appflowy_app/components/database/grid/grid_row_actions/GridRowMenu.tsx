import React, { useCallback, useMemo } from 'react';
import { ReactComponent as UpSvg } from '$app/assets/up.svg';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ReactComponent as DelSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { rowService } from '$app/application/database';
import { OrderObjectPositionTypePB } from '@/services/backend';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { useSortsCount } from '$app/components/database';
import { deleteAllSorts } from '$app/application/database/sort/sort_service';

enum RowAction {
  InsertAbove,
  InsertBelow,
  Duplicate,
  Delete,
}
interface Props extends PopoverProps {
  rowId: string;
  onOpenConfirm?: (onOk: () => Promise<void>, onCancel: () => void) => void;
}

export function GridRowMenu({ onOpenConfirm, rowId, onClose, ...props }: Props) {
  const viewId = useViewId();
  const sortsCount = useSortsCount();

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

  const renderContent = useCallback((title: string, Icon: React.FC<React.SVGProps<SVGSVGElement>>) => {
    return (
      <div className={'flex w-full items-center gap-1 px-1'}>
        <Icon className={'h-4 w-4'} />
        <div className={'flex-1'}>{title}</div>
      </div>
    );
  }, []);

  const handleAction = useCallback(
    (confirmKey?: RowAction) => {
      switch (confirmKey) {
        case RowAction.InsertAbove:
          handleInsertRecordAbove();
          break;
        case RowAction.InsertBelow:
          handleInsertRecordBelow();
          break;
        case RowAction.Duplicate:
          handleDuplicateRow();
          break;
        case RowAction.Delete:
          handleDelRow();
          break;
        default:
          break;
      }
    },
    [handleDelRow, handleDuplicateRow, handleInsertRecordAbove, handleInsertRecordBelow]
  );

  const onConfirm = useCallback(
    (key: RowAction) => {
      if (sortsCount > 0) {
        onOpenConfirm?.(
          async () => {
            await deleteAllSorts(viewId);
            handleAction(key);
          },
          () => {
            handleAction(key);
          }
        );
      } else {
        handleAction(key);
      }

      onClose?.({}, 'backdropClick');
    },
    [handleAction, onClose, onOpenConfirm, sortsCount, viewId]
  );

  const options: KeyboardNavigationOption<RowAction>[] = useMemo(
    () => [
      {
        key: RowAction.InsertAbove,
        content: renderContent(t('grid.row.insertRecordAbove'), UpSvg),
      },
      {
        key: RowAction.InsertBelow,
        content: renderContent(t('grid.row.insertRecordBelow'), AddSvg),
      },
      {
        key: RowAction.Duplicate,
        content: renderContent(t('grid.row.duplicate'), CopySvg),
      },

      {
        key: 100,
        content: <hr className={'h-[1px] w-full bg-line-divider opacity-40'} />,
        children: [],
      },
      {
        key: RowAction.Delete,
        content: renderContent(t('grid.row.delete'), DelSvg),
      },
    ],
    [renderContent, t]
  );

  return (
    <>
      <Popover
        disableRestoreFocus={true}
        keepMounted={false}
        anchorReference={'anchorPosition'}
        transformOrigin={{ vertical: 'top', horizontal: 'left' }}
        onClose={onClose}
        {...props}
      >
        <div className={'py-2'}>
          <KeyboardNavigation
            options={options}
            onConfirm={onConfirm}
            onEscape={() => {
              onClose?.({}, 'escapeKeyDown');
            }}
          />
        </div>
      </Popover>
    </>
  );
}

export default GridRowMenu;
