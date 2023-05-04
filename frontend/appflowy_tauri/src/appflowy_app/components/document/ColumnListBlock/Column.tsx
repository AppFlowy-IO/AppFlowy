import NodeComponent from '$app/components/document/Node';
import React from 'react';

export function ColumnBlock({ id, index, width }: { id: string; index: number; width: string }) {
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

      <NodeComponent
        className={`column-block py-3`}
        style={{
          flexGrow: 0,
          flexShrink: 0,
          width,
        }}
        id={id}
      />
    </>
  );
}
