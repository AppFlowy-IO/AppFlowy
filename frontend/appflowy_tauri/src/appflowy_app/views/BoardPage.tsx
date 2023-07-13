import { useParams } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { Board } from '../components/board/Board';
import { useAppSelector } from '$app/stores/store';

export const BoardPage = () => {
  const params = useParams();
  const [viewId, setViewId] = useState('');
  const pagesStore = useAppSelector((state) => state.pages);
  const page = useAppSelector((state) => (params.id ? state.pages.map[params.id] : undefined));
  const [title, setTitle] = useState('');

  useEffect(() => {
    if (page) {
      setViewId(page.id);
      setTitle(page.name);
    }
  }, [params, pagesStore, page]);

  return (
    <div className='flex h-full flex-col gap-8 px-8 pt-8'>
      {viewId?.length && <Board viewId={viewId} title={title} />}
    </div>
  );
};
