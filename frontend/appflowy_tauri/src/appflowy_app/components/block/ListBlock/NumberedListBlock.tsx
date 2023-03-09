import { Block, BlockType } from '@/appflowy_app/interfaces';
import React, { useContext, useMemo } from 'react';
import BlockComponent from '../BlockList/BlockComponent';
import { BlockContext, getDocumentBlocksMap } from '@/appflowy_app/utils/block_context';

export default function NumberedListBlock({ title, block }: { title: JSX.Element; block: Block<BlockType.ListBlock> }) {
  const { id } = useContext(BlockContext);
  const blocksMap = useMemo(() => (id ? getDocumentBlocksMap(id) : undefined), [id]);

  const index = useMemo(() => {
    if (!block.parent || !blocksMap) return 0;
    const parent = blocksMap[block.parent];
    let i = 0;
    let next = parent.firstChild;
    while (next && next !== block.id) {
      const node = blocksMap[next];
      i += 1;
      next = node.next;
    }
    return i + 1;
  }, [block.id, blocksMap]);
  return (
    <div className='numbered-list-block'>
      <div className='relative flex'>
        <div className={`relative mb-2 min-w-[24px] max-w-[24px]`}>{`${index} .`}</div>
        {title}
      </div>

      <div className='pl-[24px]'>
        {block.children?.map((item) => (
          <div key={item.id}>
            <BlockComponent block={item} />
          </div>
        ))}
      </div>
    </div>
  );
}
