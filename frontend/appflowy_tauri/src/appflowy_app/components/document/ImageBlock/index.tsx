import React, { useCallback } from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useImageBlock } from './useImageBlock';
import EditImage from '$app/components/document/ImageBlock/EditImage';
import { useBlockPopover } from '$app/components/document/_shared/BlockPopover/BlockPopover.hooks';
import ImagePlaceholder from '$app/components/document/ImageBlock/ImagePlaceholder';
import ImageRender from '$app/components/document/ImageBlock/ImageRender';

function ImageBlock({ node }: { node: NestedBlock<BlockType.ImageBlock> }) {
  const { url } = node.data;
  const { displaySize, onResizeStart, src, alignSelf, loading, error } = useImageBlock(node);

  const renderPopoverContent = useCallback(
    ({ onClose }: { onClose: () => void }) => {
      return <EditImage onClose={onClose} id={node.id} url={url} />;
    },
    [node.id, url]
  );

  const { anchorElRef, contextHolder, openPopover } = useBlockPopover({
    id: node.id,
    renderContent: renderPopoverContent,
  });

  const { width, height } = displaySize;

  return (
    <>
      <div
        ref={anchorElRef}
        className={'my-1 flex min-h-[59px] cursor-pointer flex-col justify-center overflow-hidden rounded'}
      >
        <ImageRender
          node={node}
          width={width}
          height={height}
          alignSelf={alignSelf}
          src={src}
          onResizeStart={onResizeStart}
        />
        <ImagePlaceholder
          isEmpty={!src}
          alignSelf={alignSelf}
          width={width}
          height={height}
          loading={loading}
          error={error}
          openPopover={openPopover}
        />
      </div>
      {contextHolder}
    </>
  );
}

export default ImageBlock;
