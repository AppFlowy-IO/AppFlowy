import BlockComponent from './BlockComponent';
import React, { useEffect } from 'react';
import { debounce } from '@/appflowy_app/utils/tool';
import { getBlockManagerInstance } from '../../../block_manager';

const RESIZE_DELAY = 200;

function BlockList({ blockId }: { blockId: string }) {
  const blockManager = getBlockManagerInstance();
  if (!blockManager) return null;

  const root = blockManager.createDOMTree();
  console.log('==== build tree ====', root);

  useEffect(() => {
    const resize = debounce(() => {
      // update rect cache when window resized
      blockManager.updateDOMTreeRects();
    }, RESIZE_DELAY);

    window.addEventListener('resize', resize);

    return () => {
      window.removeEventListener('resize', resize);
    };
  }, []);

  return (
    <div className='min-x-[0%] p-lg w-[900px] max-w-[100%]'>
      <div className='my-[50px] flex px-14 text-4xl font-bold'>{root?.data.title}</div>
      <div className='px-14'>
        {root && root.children.length > 0
          ? root.children.map((node) => <BlockComponent key={node.id} node={node} />)
          : null}
      </div>
    </div>
  );
}

export default React.memo(BlockList);
