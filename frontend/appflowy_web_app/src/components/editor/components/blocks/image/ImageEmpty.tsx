import { ImageBlockNode } from '@/components/editor/editor.type';
import React from 'react';
import { ReactComponent as ImageIcon } from '@/assets/image.svg';
import { useTranslation } from 'react-i18next';

function ImageEmpty (_: { containerRef: React.RefObject<HTMLDivElement>; onEscape: () => void; node: ImageBlockNode }) {
  const { t } = useTranslation();

  return (
    <>
      <div
        className={
          'flex w-full cursor-pointer select-none items-center gap-4 text-text-caption'
        }
      >
        <ImageIcon className={'w-6 h-6'} />
        {t('document.plugins.image.addAnImageDesktop')}
      </div>
    </>
  );
}

export default ImageEmpty;
