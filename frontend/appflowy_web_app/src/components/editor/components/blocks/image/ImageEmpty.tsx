import { ImageBlockNode } from '@/components/editor/editor.type';
import React from 'react';
import { ReactComponent as ImageIcon } from '$icons/16x/image.svg';
import { useTranslation } from 'react-i18next';

function ImageEmpty(_: { containerRef: React.RefObject<HTMLDivElement>; onEscape: () => void; node: ImageBlockNode }) {
  const { t } = useTranslation();

  return (
    <>
      <div
        className={
          'container-bg flex h-[48px] w-full cursor-pointer select-none items-center gap-[10px] bg-fill-list-active px-4 text-text-caption'
        }
      >
        <ImageIcon />
        {t('document.plugins.image.addAnImage')}
      </div>
    </>
  );
}

export default ImageEmpty;
