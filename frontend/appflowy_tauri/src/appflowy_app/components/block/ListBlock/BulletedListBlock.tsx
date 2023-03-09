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
    <div className='bulleted-list-block'>
      {title}
      <div>
        {block.children?.map((item) => (
          <div key={item.id}>
            <BlockComponent block={item} />
          </div>
        ))}
      </div>
    </div>
  );
}
