import React, { useCallback, useEffect, useState } from 'react';
import { TextCell } from '$app/components/database/application';
import RecordDocument from '$app/components/database/components/edit_record/RecordDocument';
import RecordHeader from '$app/components/database/components/edit_record/RecordHeader';
import { Page } from '$app_reducers/pages/slice';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { ViewLayoutPB } from '@/services/backend';

interface Props {
  cell: TextCell;
  documentId: string;
  icon?: string;
}
function EditRecord({ documentId: id, cell, icon }: Props) {
  const [page, setPage] = useState<Page | null>(null);

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
      if (e.code === 3) {
        try {
          const page = await controller.createOrphanPage({
            name: '',
            layout: ViewLayoutPB.Document,
          });

          setPage(page);
        } catch (e) {
          console.error(e);
        }
      }
    }
  }, [id]);

  useEffect(() => {
    void loadPage();
  }, [loadPage]);

  const getDocumentTitle = useCallback(() => {
    return <RecordHeader page={page} cell={cell} icon={icon} />;
  }, [cell, icon, page]);

  return (
    <div className={'h-full px-12 py-6'}>
      {page && <RecordDocument getDocumentTitle={getDocumentTitle} documentId={id} />}
    </div>
  );
}

export default React.memo(EditRecord);
