import React, { useCallback } from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useImageBlock } from './useImageBlock';
import { useBlockPopover } from '$app/components/document/_shared/BlockPopover/BlockPopover.hooks';
import ImagePlaceholder from '$app/components/document/ImageBlock/ImagePlaceholder';
import ImageRender from '$app/components/document/ImageBlock/ImageRender';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import ImageEdit from '$app/components/document/_shared/UploadImage/ImageEdit';

function ImageBlock({ node }: { node: NestedBlock<BlockType.ImageBlock> }) {
  const { url } = node.data;
  const { displaySize, onResizeStart, src, alignSelf, loading, error } = useImageBlock(node);
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();
  const id = node.id;

  const renderPopoverContent = useCallback(
    ({ onClose }: { onClose: () => void }) => {
      const onSubmitUrl = (url: string) => {
        if (!url) return;
        dispatch(
          updateNodeDataThunk({
            id,
            data: {
              url,
            },
            controller,
          })
        );
        onClose();
      };

      return (
        <div className={'w-[540px]'}>
          <ImageEdit url={url} onSubmitUrl={onSubmitUrl} />
        </div>
      );
    },
    [controller, dispatch, id, url]
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
