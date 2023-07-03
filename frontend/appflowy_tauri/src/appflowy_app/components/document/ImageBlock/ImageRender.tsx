import React, { useCallback, useState } from 'react';
import ImageToolbar from '$app/components/document/ImageBlock/ImageToolbar';
import { BlockType, NestedBlock } from '$app/interfaces/document';

function ImageRender({
  src,
  node,
  width,
  height,
  alignSelf,
  onResizeStart,
}: {
  node: NestedBlock<BlockType.ImageBlock>;
  width: number;
  height: number;
  alignSelf: string;
  src: string;
  onResizeStart: (e: React.MouseEvent<HTMLDivElement>, isLeft: boolean) => void;
}) {
  const [toolbarOpen, setToolbarOpen] = useState<boolean>(false);

  const renderResizer = useCallback(
    (isLeft: boolean) => {
      return (
        <div
          onMouseDown={(e) => onResizeStart(e, isLeft)}
          className={`${toolbarOpen ? 'pointer-events-auto' : 'pointer-events-none'} absolute z-[2] ${
            isLeft ? 'left-0' : 'right-0'
          } top-0 flex h-[100%] w-[15px] cursor-col-resize items-center justify-center`}
        >
          <div
            className={`h-[48px] max-h-[50%] w-2 rounded-[20px] border border-solid border-main-selector bg-shade-3 ${
              toolbarOpen ? 'opacity-1' : 'opacity-0'
            } transition-opacity duration-300 `}
          />
        </div>
      );
    },
    [onResizeStart, toolbarOpen]
  );

  return (
    <div
      contentEditable={false}
      onMouseEnter={() => setToolbarOpen(true)}
      onMouseLeave={() => setToolbarOpen(false)}
      style={{
        width: width + 'px',
        height: height + 'px',
        alignSelf,
      }}
      className={`relative cursor-default`}
    >
      {src && (
        <img
          src={src}
          className={'relative cursor-pointer'}
          style={{
            height: height + 'px',
            width: width + 'px',
          }}
        />
      )}
      {renderResizer(true)}
      {renderResizer(false)}
      <ImageToolbar id={node.id} open={toolbarOpen} align={node.data.align} />
    </div>
  );
}

export default ImageRender;
