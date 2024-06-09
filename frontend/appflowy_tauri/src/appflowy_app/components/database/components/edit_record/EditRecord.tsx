import React, { useCallback, useEffect, useMemo, useState } from 'react';
import RecordDocument from '$app/components/database/components/edit_record/RecordDocument';
import RecordHeader from '$app/components/database/components/edit_record/RecordHeader';
import { Page } from '$app_reducers/pages/slice';
import { ErrorCode, ViewLayoutPB } from '@/services/backend';
import { Log } from '$app/utils/log';
import { useDatabase } from '$app/components/database';
import { createOrphanPage, getPage } from '$app/application/folder/page.service';

interface Props {
  rowId: string;
}

function EditRecord({ rowId }: Props) {
  const { rowMetas } = useDatabase();
  const row = useMemo(() => {
    return rowMetas.find((row) => row.id === rowId);
  }, [rowMetas, rowId]);
  const [page, setPage] = useState<Page | null>(null);
  const id = row?.documentId;

  const loadPage = useCallback(async () => {
    if (!id) return;

    try {
      const page = await getPage(id);

      setPage(page);
    } catch (e) {
      // Record not found
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      if (e.code === ErrorCode.RecordNotFound) {
        try {
          const page = await createOrphanPage({
            view_id: id,
            name: '',
            layout: ViewLayoutPB.Document,
          });

          setPage(page);
        } catch (e) {
          Log.error(e);
        }
      }
    }
  }, [id]);

  useEffect(() => {
    void loadPage();
  }, [loadPage]);

  if (!id || !page) return null;

  return (
    <>
      <RecordHeader page={page} row={row} />
      <RecordDocument documentId={id} />
    </>
  );
}

export default EditRecord;
