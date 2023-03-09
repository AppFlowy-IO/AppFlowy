import React, { useContext, useMemo } from 'react';
import { Circle, CircleOutlined, Square } from '@mui/icons-material';
import { Block, BlockType } from '@/appflowy_app/interfaces';
import { BlockContext } from '@/appflowy_app/utils/block_context';
import { getDocumentBlocksMap } from '../../../utils/block_context';
import BlockComponent from '../BlockList/BlockComponent';

export default function BulletedListBlock({ title, block }: { title: JSX.Element; block: Block<BlockType.ListBlock> }) {
  const { id } = useContext(BlockContext);
  const blocksMap = useMemo(() => (id ? getDocumentBlocksMap(id) : undefined), [id]);

  return (
    <div className='bulleted-list-block relative'>
      <div className='relative flex'>
        <div className={`relative mb-2 min-w-[24px] leading-5`}>
          <Circle sx={{ width: 8, height: 8 }} />
        </div>
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
