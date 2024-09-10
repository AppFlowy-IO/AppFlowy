import { GalleryLayout } from '@/application/types';
import { GalleryPreview } from '@/components/_shared/gallery-preview';
import { notify } from '@/components/_shared/notify';
import Carousel from '@/components/editor/components/blocks/gallery/Carousel';
import GalleryToolbar from '@/components/editor/components/blocks/gallery/GalleryToolbar';
import ImageGallery from '@/components/editor/components/blocks/gallery/ImageGallery';
import { EditorElementProps, GalleryBlockNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import React, { forwardRef, memo, Suspense, useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

const GalleryBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<GalleryBlockNode>>(({
    node,
    children,
    ...attributes
  }, ref) => {
    const { t } = useTranslation();
    const { images, layout } = useMemo(() => node.data || {}, [node.data]);
    const [openPreview, setOpenPreview] = React.useState(false);
    const previewIndexRef = React.useRef(0);
    const [hovered, setHovered] = useState(false);

    const className = useMemo(() => {
      const classList = ['gallery-block', 'relative', 'w-full', 'cursor-default', attributes.className || ''];

      return classList.join(' ');
    }, [attributes.className]);

    const photos = useMemo(() => {
      return images.map(image => {
        const url = new URL(image.url);

        url.searchParams.set('auto', 'format');
        url.searchParams.set('fit', 'crop');
        return {
          src: image.url,
          thumb: url.toString() + '&w=240&q=80',
          responsive: [
            url.toString() + '&w=480&q=80 480',
            url.toString() + '&w=800&q=80 800',
          ].join(', '),
        };
      });
    }, [images]);

    const handleOpenPreview = useCallback(() => {
      setOpenPreview(true);
    }, []);

    const handleCopy = useCallback(async () => {
      const image = photos[previewIndexRef.current];

      if (!image) {
        return;
      }

      await copyTextToClipboard(image.src);
      notify.success(t('publish.copy.imageBlock'));
    }, [photos, t]);

    const handleDownload = useCallback(() => {
      const image = photos[previewIndexRef.current];

      if (!image) {
        return;
      }

      window.open(image.src, '_blank');
    }, [photos]);

    const handlePreviewIndex = useCallback((index: number) => {
      previewIndexRef.current = index;
    }, []);

    return (
      <div
        ref={ref} {...attributes} className={className} onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
      >
        <div className={'absolute left-0 top-0 h-full w-full pointer-events-none'}>
          {children}
        </div>
        {photos.length > 0 ?
          (layout === GalleryLayout.Carousel ?
              <Carousel
                onPreview={handlePreviewIndex}
                images={photos}
                autoplay={!openPreview}
              /> :
              <ImageGallery
                onPreview={(index) => {
                  previewIndexRef.current = index;
                  handleOpenPreview();
                }} images={photos}
              />
          ) : null}
        {hovered &&
          <GalleryToolbar onCopy={handleCopy} onDownload={handleDownload} onOpenPreview={handleOpenPreview} />}

        {openPreview && <Suspense><GalleryPreview
          images={photos}
          previewIndex={previewIndexRef.current}
          open={openPreview}
          onClose={() => {
            setOpenPreview(false);
          }}
        /></Suspense>}

      </div>
    );
  }));

export default GalleryBlock;