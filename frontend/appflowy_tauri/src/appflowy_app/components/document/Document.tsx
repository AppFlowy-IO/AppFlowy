import React, { useCallback, useEffect, useMemo, useState } from 'react';
import Editor from '$app/components/editor/Editor';
import { DocumentHeader } from 'src/appflowy_app/components/document/document_header';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { updatePageName } from '$app_reducers/pages/async_actions';
import { PageCover } from '$app_reducers/pages/slice';

export function Document({ id }: { id: string }) {
  const page = useAppSelector((state) => state.pages.pageMap[id]);

  const [cover, setCover] = useState<PageCover | undefined>(undefined);
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

  const view = useMemo(() => {
    return {
      ...page,
      cover,
    };
  }, [page, cover]);

  useEffect(() => {
    return () => {
      setCover(undefined);
    };
  }, [id]);

  if (!page) return null;

  return (
    <div className={'relative w-full'}>
      <DocumentHeader onUpdateCover={setCover} page={view} />
      <div className={'flex w-full justify-center'}>
        <div className={'max-w-screen w-[964px] min-w-0'}>
          <Editor id={id} cover={cover} onCoverChange={setCover} onTitleChange={onTitleChange} title={page.name} />
        </div>
      </div>
    </div>
  );
}

export default Document;
