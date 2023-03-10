import { useBlockList } from './BlockList.hooks';
import BlockComponent from './BlockComponent';

export default function BlockList() {
  const { blockList, title } = useBlockList();

  return (
    <div className='min-x-[0%] p-lg w-[900px] max-w-[100%]'>
      <div className='my-[50px] flex px-14 text-4xl font-bold'>{title}</div>
      <div className='px-14'>
        {blockList?.map((block) => (
          <BlockComponent key={block.id} block={block} />
        ))}
      </div>
    </div>
  );
}
