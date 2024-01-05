import React, { useCallback } from 'react';
import { Editor } from 'src/appflowy_app/components/editor';
import { DocumentHeader } from 'src/appflowy_app/components/document/document_header';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { updatePageName } from '$app_reducers/pages/async_actions';

export function Document({ id }: { id: string }) {
  const page = useAppSelector((state) => state.pages.pageMap[id]);

  const dispatch = useAppDispatch();

  const onTitleChange = useCallback(
    (newTitle: string) => {
      void dispatch(
        updatePageName({
          id,
          name: newTitle,
        })
      );
    },
    [dispatch, id]
  );

  if (!page) return null;

  return (
    <div className={'relative'}>
      <DocumentHeader page={page} />
      <Editor id={id} onTitleChange={onTitleChange} title={page.name} />
    </div>
  );
}

export default Document;
