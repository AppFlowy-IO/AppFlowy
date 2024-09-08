import React, { memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import LightGallery from 'lightgallery/react';
import 'lightgallery/css/lightgallery.css';
import 'lightgallery/css/lg-thumbnail.css';
import 'lightgallery/css/lg-autoplay.css';
import './carousel.scss';
import lgThumbnail from 'lightgallery/plugins/thumbnail';
import lgAutoplay from 'lightgallery/plugins/autoplay';

const plugins = [lgThumbnail, lgAutoplay];

function Carousel ({ images, onPreview, autoplay }: {
  images: {
    src: string;
    thumb: string;
    responsive: string;
  }[];
  onPreview: (index: number) => void;
  autoplay?: boolean;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const instance = useRef<any | null>(null);
  const [rendered, setRendered] = useState(false);

  useEffect(() => {
    setRendered(true);

  }, []);

  useEffect(() => {
    if (!instance.current) return;
    if (autoplay) {
      instance.current.plugins[1].startAutoPlay();
    } else {
      instance.current.plugins[1].stopAutoPlay();
    }

  }, [autoplay]);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleInit = useCallback((detail: any) => {
    instance.current = detail.instance;
    detail.instance.openGallery(Math.ceil(images.length / 2) - 1);
  }, [images]);

  const handleAfterSlide = useCallback((detail: { index: number }) => {
    onPreview(detail.index);
  }, [onPreview]);

  const renderCarousel = useMemo(() => {
    if (!containerRef.current || !rendered) return;
    return <LightGallery
      container={containerRef.current}
      onInit={handleInit}
      onAfterSlide={handleAfterSlide}
      plugins={plugins}
      dynamic={true}
      dynamicEl={images}
      autoplay={true}
      progressBar={false}
      speed={500}
      slideDelay={0}
      thumbWidth={90}
      thumbMargin={6}
      closable={false}
    />;
  }, [handleAfterSlide, handleInit, images, rendered]);

  return (
    <div className={'flex flex-col images-carousel'}>
      <div className={'relative carousel-container'} ref={containerRef}></div>

      {renderCarousel}

    </div>
  );
}

export default memo(Carousel);