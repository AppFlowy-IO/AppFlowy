import { URLCellDataPB } from '@/services/backend';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';
import { useEffect, useState } from 'react';
import { URLCellController } from '$app/stores/effects/database/cell/controller_builder';

export const EditCellUrl = ({
  data,
  cellController,
}: {
  data: URLCellDataPB | undefined;
  cellController: CellController<any, any>;
}) => {
  const [url, setUrl] = useState('');
  const [content, setContent] = useState('');

  useEffect(() => {
    setUrl((data as URLCellDataPB)?.url || '');
  }, [data]);

  const save = async () => {
    await (cellController as URLCellController)?.saveCellData(url);
    // console.log('saving url');
  };

  return (
    <div className={'flex flex-col px-4 py-2'}>
      <label className={'mb-1'}>URL:</label>
      <input
        value={url}
        onChange={(e) => setUrl(e.target.value)}
        className={'-mx-2 mb-4 rounded bg-white px-2 py-1'}
        onBlur={() => save()}
      />
      <label className={'mb-1'}>Content:</label>
      <input
        value={content}
        onChange={(e) => setContent(e.target.value)}
        className={'-mx-2 mb-2 rounded bg-white px-2 py-1'}
        onBlur={() => save()}
      />
    </div>
  );
};
