import { ImageBlockNode } from '@/components/editor/editor.type';
import React from 'react';
import { ReactComponent as ImageIcon } from '@/assets/image.svg';
import { useTranslation } from 'react-i18next';

function ImageEmpty(_: { containerRef: React.RefObject<HTMLDivElement>; onEscape: () => void; node: ImageBlockNode }) {
  const { t } = useTranslation();

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
    </>
  );
}

export default ImageEmpty;
