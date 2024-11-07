import { View } from '@/application/types';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import TableSkeleton from '@/components/_shared/skeleton/TableSkeleton';
import { useAppHandlers, useAppTrash, useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { Button, IconButton, TableContainer, Tooltip } from '@mui/material';
import dayjs from 'dayjs';
import React, { useCallback, useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import { ReactComponent as TrashIcon } from '@/assets/trash.svg';
import { ReactComponent as RestoreIcon } from '@/assets/restore.svg';

function TrashPage () {
  const { t } = useTranslation();

  const currentWorkspaceId = useCurrentWorkspaceId();
  const { trashList, loadTrash } = useAppTrash();
  const [deleteViewId, setDeleteViewId] = React.useState<string | undefined>(undefined);
  const deleteView = useMemo(() => {
    return trashList?.find((view) => view.view_id === deleteViewId);
  }, [deleteViewId, trashList]);
  const {
    deleteTrash,
    restorePage,
  } = useAppHandlers();

  const handleRestore = useCallback(async (viewId?: string) => {
    try {
      await restorePage?.(viewId);
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(`Failed to restore page: ${e.message}`);
    }
  }, [restorePage]);

  const handleDelete = useCallback(async (viewId?: string) => {
    try {
      await deleteTrash?.(viewId);
      setDeleteViewId(undefined);
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(`Failed to delete page: ${e.message}`);
    }
  }, [deleteTrash]);

  useEffect(() => {
    void (async () => {
      if (!currentWorkspaceId) return;
      try {
        await loadTrash?.(currentWorkspaceId);
      } catch (e) {
        notify.error('Failed to load trash');
      }
    })();
  }, [loadTrash, currentWorkspaceId]);

  const columns = useMemo(() => {
    return [
      { id: 'name', label: t('trash.pageHeader.fileName'), minWidth: 170 },
      { id: 'last_edited_time', label: t('trash.pageHeader.lastModified'), minWidth: 170 },
      { id: 'created_at', label: t('trash.pageHeader.created'), minWidth: 170 },
      { id: 'actions', label: '', minWidth: 170 },
    ];
  }, [t]);

  const renderCell = useCallback((column: typeof columns[0], row: View) => {
    // eslint-disable-next-line
    // @ts-ignore
    const value = row[column.id];
    let content = null;

    if (column.id === 'actions') {
      content = <div className={'flex gap-2'}>
        <Tooltip title={t('trash.restore')}>
          <IconButton
            size={'small'}
            onClick={
              () => {
                void handleRestore(row.view_id);
              }
            }
          >
            <RestoreIcon />
          </IconButton>
        </Tooltip>
        <Tooltip title={t('button.delete')}>
          <IconButton
            size={'small'}
            onClick={() => {
              setDeleteViewId(row.view_id);
            }}
            className={'hover:text-function-error'}
          >
            <TrashIcon />
          </IconButton>
        </Tooltip>
      </div>;
    } else if (column.id === 'created_at' || column.id === 'last_edited_time') {
      content = dayjs(value).format('MM/DD/YYYY hh:mm A');
    } else {
      content = value || t('menuAppHeader.defaultNewPageName');
    }

    return (
      <TableCell
        key={column.id}
        align={'left'}
        className={'font-medium'}
      >
        {content}
      </TableCell>
    );
  }, [handleRestore, t]);

  return (
    <div
      style={{
        height: 'calc(100vh - 48px)',
      }}
      className={'flex-1 h-full flex-col flex w-full items-center'}
    >
      <div className={'w-[964px] flex flex-col min-w-0 max-w-full px-6 gap-4 py-10 h-full'}>
        <div
          className={'flex items-center justify-between px-4'}
        >
          <span className={'text-text-title text-xl font-medium'}>{t('trash.text')}</span>
          <div className={'flex gap-2'}>
            <Button
              size={'small'}
              onClick={() => handleRestore()}
              startIcon={<RestoreIcon />}
              color={'inherit'}
            >{t('trash.restoreAll')}</Button>
            <Button
              size={'small'}
              className={'hover:text-function-error'}
              onClick={() => setDeleteViewId('all')}
              startIcon={<TrashIcon />}
              color={'inherit'}
            >{t('trash.deleteAll')}</Button>
          </div>
        </div>
        <div className={'flex flex-col gap-2 w-full flex-1 overflow-hidden'}>
          {!trashList ? <TableSkeleton
              rows={8}
              columns={4}
            /> :
            <TableContainer
              className={'appflowy-scroller'}
              sx={{ maxHeight: '100%' }}
            >
              <Table
                stickyHeader
                aria-label="sticky table"
              >
                <TableHead>
                  <TableRow>
                    {columns.map((column) => (
                      <TableCell
                        className={'font-medium text-text-caption'}
                        key={column.id}
                        align={'left'}
                        style={{ minWidth: column.minWidth }}
                      >
                        {column.label}
                      </TableCell>
                    ))}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {trashList
                    .map((row) => {
                      return (
                        <TableRow
                          hover
                          role="checkbox"
                          tabIndex={-1}
                          key={row.view_id}
                        >
                          {columns.map((column) => {
                            return renderCell(column, row);
                          })}
                        </TableRow>
                      );
                    })}
                </TableBody>
              </Table>
            </TableContainer>
          }
        </div>
      </div>

      <NormalModal
        keepMounted={false}
        okText={t('button.delete')}
        cancelText={t('button.cancel')}
        open={deleteViewId !== undefined}
        danger={true}
        onClose={() => setDeleteViewId(undefined)}
        title={
          <div className={'flex font-semibold items-center w-full text-left'}>{`${t('button.delete')}: ${deleteView?.name || t('menuAppHeader.defaultNewPageName')}`}</div>
        }
        onOk={() => {
          void handleDelete(deleteViewId === 'all' ? undefined : deleteViewId);
        }}
        PaperProps={{
          className: 'w-[420px] max-w-[70vw]',
        }}
      >
        <div className={'text-text-caption font-normal'}>{deleteViewId === 'all' ? t('trash.confirmDeleteAll.caption') : t('trash.confirmDeleteTitle')}</div>

      </NormalModal>
    </div>
  );
}

export default TrashPage;