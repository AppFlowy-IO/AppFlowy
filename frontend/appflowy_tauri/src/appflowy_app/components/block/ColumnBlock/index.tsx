import React from 'react';
import { Block, BlockType } from '$app/interfaces/index';
import BlockComponent from '../BlockList/BlockComponent';

export default function ColumnBlock({
  block,
  resizerWidth,
  index,
}: {
  block: Block<BlockType.ColumnBlock>;
  resizerWidth: number;
  index: number;
}) {
  const renderResizer = () => {
    return (
      <div className={`relative w-[46px] flex-shrink-0 flex-grow-0 transition-opacity`} style={{ opacity: 0 }}></div>
    );
  };
  return (
    <>
      {index === 0 ? (
        <div className='contents'>
          <div
            className='absolute flex'
            style={{
              inset: '0px 100% 0px auto',
            }}
          >
            {renderResizer()}
          </div>
        </div>
      ) : (
        renderResizer()
      )}

      <BlockComponent
        className={`column-block py-3`}
        style={{
          flexGrow: 0,
          flexShrink: 0,
          width: `calc((100% - ${resizerWidth}px) * ${block.data.ratio})`,
        }}
        block={block}
      >
        {block.children?.map((item) => (
          <BlockComponent key={item.id} block={item} />
        ))}
      </BlockComponent>
    </>
  );
}
