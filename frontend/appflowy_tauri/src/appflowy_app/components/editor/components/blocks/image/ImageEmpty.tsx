import React, { useEffect } from 'react';
import { ReactComponent as ImageIcon } from '$app/assets/image.svg';
import { useTranslation } from 'react-i18next';
import UploadPopover from '$app/components/editor/components/blocks/image/UploadPopover';
import { EditorNodeType, ImageNode } from '$app/application/document/document.types';
import { useEditorBlockDispatch, useEditorBlockState } from '$app/components/editor/stores/block';

function ImageEmpty({
  containerRef,
  onEscape,
  node,
}: {
  containerRef: React.RefObject<HTMLDivElement>;
  onEscape: () => void;
  node: ImageNode;
}) {
  const { t } = useTranslation();
  const state = useEditorBlockState(EditorNodeType.ImageBlock);
  const open = Boolean(state?.popoverOpen && state?.blockId === node.blockId && containerRef.current);
  const { openPopover, closePopover } = useEditorBlockDispatch();

  useEffect(() => {
    const container = containerRef.current;

    if (!container) {
      return;
    }

    const handleClick = () => {
      openPopover(EditorNodeType.ImageBlock, node.blockId);
    };

    container.addEventListener('click', handleClick);
    return () => {
      container.removeEventListener('click', handleClick);
    };
  }, [containerRef, node.blockId, openPopover]);
  return (
    <>
      <div
        className={
          'container-bg flex h-[48px] w-full cursor-pointer select-none items-center gap-[10px] bg-content-blue-50 px-4 text-text-caption'
        }
      >
        <ImageIcon />
        {t('document.plugins.image.addAnImage')}
      </div>
      {open && (
        <UploadPopover
          anchorEl={containerRef.current}
          open={open}
          node={node}
          onClose={() => {
            closePopover(EditorNodeType.ImageBlock);
            onEscape();
          }}
        />
      )}
    </>
  );
}

export default ImageEmpty;
