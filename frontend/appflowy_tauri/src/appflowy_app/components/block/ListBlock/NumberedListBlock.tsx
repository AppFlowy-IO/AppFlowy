import { TreeNode } from '@/appflowy_app/block_editor/tree_node';
import React, { useMemo } from 'react';
import BlockComponent from '../BlockList/BlockComponent';
import { BlockType } from '@/appflowy_app/interfaces';
import { Block } from '@/appflowy_app/block_editor/block';

export default function NumberedListBlock({ title, node }: { title: JSX.Element; node: TreeNode }) {
  const index = useMemo(() => {
    const prev = node.block.prev;
    if (prev?.type === BlockType.ListBlock && (prev as Block<BlockType.ListBlock>).data.type === 'numbered') {
      const i = node.parent?.children?.findIndex((item) => item.id === node.id) || 0;
      return i + 1;
    }
    return 1;
  }, [node]);
  return (
    <div className='numbered-list-block'>
      <div className='relative flex'>
        <div
          className={`relative flex h-[calc(1.5em_+_3px_+_3px)] min-w-[24px] max-w-[24px] select-none items-center`}
        >{`${index} .`}</div>
        {title}
      </div>

      <div className='pl-[24px]'>
        {node.children?.map((item) => (
          <div key={item.id}>
            <BlockComponent node={item} />
          </div>
        ))}
      </div>
    </div>
  );
}
