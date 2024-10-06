import { notify } from '@/components/_shared/notify';
import TableSkeleton from '@/components/_shared/skeleton/TableSkeleton';
import { useAppTrash, useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { TableContainer } from '@mui/material';
import dayjs from 'dayjs';
import React, { useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';

function TrashPage () {
  const { t } = useTranslation();

  const currentWorkspaceId = useCurrentWorkspaceId();
  const { trashList, loadTrash } = useAppTrash();

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

    ];
  }, [t]);

  return (
    <div
      style={{
        height: 'calc(100vh - 48px)',
      }} className={'flex-1 h-full flex-col flex w-full items-center'}
    >
      <div className={'w-[964px] flex flex-col min-w-0 max-w-full px-6 py-10 h-full'}>
        <div
          className={'flex items-center justify-between'}
        >
          <span className={'text-text-title text-xl font-medium'}>{t('trash.text')}</span>
        </div>
        <div className={'flex flex-col gap-2 w-full flex-1 overflow-hidden'}>
          {!trashList ? <TableSkeleton rows={8} columns={3} /> :
            <TableContainer className={'appflowy-scroller'} sx={{ maxHeight: '100%' }}>
              <Table stickyHeader aria-label="sticky table">
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
                        <TableRow hover role="checkbox" tabIndex={-1} key={row.view_id}>
                          {columns.map((column) => {
                            // eslint-disable-next-line
                            // @ts-ignore
                            const value = row[column.id];

                            return (
                              <TableCell key={column.id} align={'left'} className={'font-medium'}>
                                {column.id === 'created_at' || column.id === 'last_edited_time' ? dayjs(value).format('MM/DD/YYYY hh:mm A') : value}
                              </TableCell>
                            );
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

    </div>
  );
}

export default TrashPage;