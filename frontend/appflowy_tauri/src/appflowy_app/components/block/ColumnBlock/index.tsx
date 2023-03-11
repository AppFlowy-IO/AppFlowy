import React from 'react';
import { TreeNodeImp } from '$app/interfaces/index';
import BlockComponent from '../BlockList/BlockComponent';

export default function ColumnBlock({
  node,
  resizerWidth,
  index,
}: {
  node: TreeNodeImp;
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
          width: `calc((100% - ${resizerWidth}px) * ${node.data.ratio})`,
        }}
        node={node}
      >
        {node.children?.map((item) => (
          <BlockComponent key={item.id} node={item} />
        ))}
      </BlockComponent>
    </>
  );
}
