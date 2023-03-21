import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import BlockComponent from '../BlockComponent';
import { BlockType } from '@/appflowy_app/interfaces';
import { Block } from '@/appflowy_app/block_editor/core/block';

export default function NumberedListBlock({ title, node }: { title: JSX.Element; node: TreeNode }) {
  let prev = node.block.prev;
  let index = 1;
  while (prev && prev.type === BlockType.ListBlock && (prev as Block<BlockType.ListBlock>).data.type === 'numbered') {
    index++;
    prev = prev.prev;
  }
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
