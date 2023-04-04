import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import NodeComponent from '../Node';

export default function NumberedListBlock({
  title,
  node,
  childIds,
}: {
  title: JSX.Element;
  node: Node;
  childIds?: string[];
}) {
  const index = 1;
  return (
    <div className='numbered-list-block'>
      <div className='relative flex'>
        <div
          className={`relative flex h-[calc(1.5em_+_3px_+_3px)] min-w-[24px] max-w-[24px] select-none items-center`}
        >{`${index} .`}</div>
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
