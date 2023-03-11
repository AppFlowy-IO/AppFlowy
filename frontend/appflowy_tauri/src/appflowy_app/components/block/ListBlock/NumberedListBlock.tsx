import { TreeNodeImp } from '@/appflowy_app/interfaces';
import React, { useMemo } from 'react';
import BlockComponent from '../BlockList/BlockComponent';

export default function NumberedListBlock({ title, node }: { title: JSX.Element; node: TreeNodeImp }) {
  const index = useMemo(() => {
    const i = node.parent?.children?.findIndex((item) => item.id === node.id) || 0;
    return i + 1;
  }, [node]);
  return (
    <div className='numbered-list-block'>
      <div className='relative flex'>
        <div className={`relative mb-2 min-w-[24px] max-w-[24px]`}>{`${index} .`}</div>
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
