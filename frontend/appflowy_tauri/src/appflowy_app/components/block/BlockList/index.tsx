import BlockComponent from './BlockComponent';
import { buildTree, updateDocumentRectCache } from '@/appflowy_app/utils/tree';
import { getDocumentBlocksMap } from '$app/utils/block_context';
import { Block } from '$app/interfaces/index';
import React, { useEffect } from 'react';
import { debounce } from '@/appflowy_app/utils/tool';

const RESIZE_DELAY = 200;

function BlockList({ blockId }: { blockId: string }) {
  const blocksMap = getDocumentBlocksMap(blockId) || {};

  const root = buildTree(blockId, blocksMap);

  console.log('==== build tree ====', root);

  const renderNode = (block: Block) => {
    return <BlockComponent key={block.id} block={block} />;
  };

  useEffect(() => {
    updateDocumentRectCache(blockId);
    const resize = debounce(() => {
      updateDocumentRectCache(blockId);
    }, RESIZE_DELAY);

    window.addEventListener('resize', resize);

    return () => {
      window.removeEventListener('resize', resize);
    };
  }, [blockId]);

  return (
    <div className='min-x-[0%] p-lg w-[900px] max-w-[100%]'>
      <div className='my-[50px] flex px-14 text-4xl font-bold'>{root?.data.title}</div>
      <div className='px-14'>{root?.children?.map(renderNode)}</div>
    </div>
  );
}

export default React.memo(BlockList);
