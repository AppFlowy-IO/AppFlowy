import { useParams } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { Board } from '../components/board/Board';

export const BoardPage = () => {
  const params = useParams();
  const [databaseId, setDatabaseId] = useState('');

  useEffect(() => {
    if (params?.id?.length) {
      // setDatabaseId(params.id);
      setDatabaseId('testDb');
    }
  }, [params]);

  return (
    <div className='flex h-full flex-col gap-8 px-8 pt-8'>
      <h1 className='text-4xl font-bold'>Board</h1>
      {databaseId?.length && <Board />}
    </div>
  );
};
