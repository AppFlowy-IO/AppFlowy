import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import { Circle } from '@mui/icons-material';
import NodeComponent from '../Node';

export default function BulletedListBlock({
  title,
  node,
  childIds,
}: {
  title: JSX.Element;
  node: Node;
  childIds?: string[];
}) {
  return (
    <div className='bulleted-list-block relative'>
      <div className='relative flex'>
        <div className={`relative flex h-[calc(1.5em_+_3px_+_3px)] min-w-[24px] select-none items-center`}>
          <Circle sx={{ width: 8, height: 8 }} />
        </div>
        {title}
      </div>

      <div className='pl-[24px]'>
        {childIds?.map((item) => (
          <NodeComponent key={item} id={item} />
        ))}
      </div>
    </div>
  );
}
