import { Circle } from '@mui/icons-material';

import BlockComponent from '../BlockList/BlockComponent';
import { TreeNodeImp } from '$app/interfaces/index';

export default function BulletedListBlock({ title, node }: { title: JSX.Element; node: TreeNodeImp }) {
  return (
    <div className='bulleted-list-block relative'>
      <div className='relative flex'>
        <div className={`relative mb-2 min-w-[24px] leading-5`}>
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
