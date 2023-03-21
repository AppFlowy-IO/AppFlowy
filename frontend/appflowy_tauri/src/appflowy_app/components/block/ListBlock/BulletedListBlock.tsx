import { Circle } from '@mui/icons-material';

import BlockComponent from '../BlockComponent';
import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';

export default function BulletedListBlock({ title, node }: { title: JSX.Element; node: TreeNode }) {
  return (
    <div className='bulleted-list-block relative'>
      <div className='relative flex'>
        <div className={`relative flex h-[calc(1.5em_+_3px_+_3px)] min-w-[24px] select-none items-center`}>
          <Circle sx={{ width: 8, height: 8 }} />
        </div>
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
