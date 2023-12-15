import React, { useCallback, useEffect, useMemo, useState } from 'react';
import RecordDocument from '$app/components/database/components/edit_record/RecordDocument';
import RecordHeader from '$app/components/database/components/edit_record/RecordHeader';
import { Page } from '$app_reducers/pages/slice';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { ErrorCode, ViewLayoutPB } from '@/services/backend';
import { Log } from '$app/utils/log';
import { useDatabase } from '$app/components/database';

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
    const controller = new PageController(id);

    try {
      const page = await controller.getPage();

      setPage(page);
    } catch (e) {
      // Record not found
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      if (e.code === ErrorCode.RecordNotFound) {
        try {
          const page = await controller.createOrphanPage({
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

  const getDocumentTitle = useCallback(() => {
    return row ? <RecordHeader page={page} row={row} /> : null;
  }, [row, page]);

  if (!id) return null;

  return (
    <div className={'h-full px-12 py-6'}>
      {page && <RecordDocument getDocumentTitle={getDocumentTitle} documentId={id} />}
    </div>
  );
}

export default React.memo(EditRecord);
