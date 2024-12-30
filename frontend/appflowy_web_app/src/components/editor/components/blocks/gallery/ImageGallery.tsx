import React, { useCallback, useMemo } from 'react';

const GROUP_SIZE = 4;

interface ImageType {
  src: string;
  thumb: string;
  responsive: string;
}

interface ImageGalleryProps {
  images: ImageType[];
  onPreview: (index: number) => void;
}

const ImageGallery: React.FC<ImageGalleryProps> = ({ images, onPreview }) => {
  const optimizeImageUrl = useCallback((src: string, width: number, height: number): string => {
    const url = new URL(src);

    url.searchParams.set('auto', 'format');
    url.searchParams.set('fit', 'crop');
    url.searchParams.set('q', '80');
    return `${url.toString()}&w=${width}&h=${height}`;
  }, []);

  const groupImages = useCallback((images: ImageType[], groupSize: number = GROUP_SIZE): string[][] => {
    return images.reduce((acc, _, index) => {
      if (index % groupSize === 0) {
        acc.push(images.slice(index, index + groupSize).map(img => img.src));
      }

      return acc;
    }, [] as string[][]);
  }, []);

  const imageGroups = useMemo(() => groupImages(images), [images, groupImages]);

  const renderImage = useCallback((image: string, width: number, height: number, index: number) => (
    <img
      key={image}
      alt={`Image ${index + 1}`}
      src={optimizeImageUrl(image, width, height)}
      className="w-full h-full object-cover rounded cursor-pointer transition-transform hover:scale-105"
      onClick={() => onPreview(index)}
    />
  ), [optimizeImageUrl, onPreview]);

  const renderGroup = useCallback((group: string[], groupIndex: number) => {
    const startIndex = groupIndex * GROUP_SIZE;
    const isOdd = groupIndex % 2 !== 0;

    const renderLargeImage = (image: string, index: number) => (
      <div className="w-1/2 h-96 p-1">
        {renderImage(image, 600, 800, index)}
      </div>
    );

    const renderSmallImages = (images: string[], startIdx: number) => (
      <div className="w-1/2 h-96 flex flex-col">
        {images.length === 2 ? (
          <>
            <div className="h-1/2 p-1">{images[0] && renderImage(images[0], 600, 400, startIdx)}</div>
            <div className="h-1/2 p-1">{images[1] && renderImage(images[1], 600, 400, startIdx + 1)}</div>
          </>
        ) : (
          <>
            <div className="h-1/2 flex">
              <div className="w-1/2 p-1">{images[0] && renderImage(images[0], 300, 400, startIdx)}</div>
              <div className="w-1/2 p-1">{images[1] && renderImage(images[1], 300, 400, startIdx + 1)}</div>
            </div>
            <div className="h-1/2 p-1">{images[2] && renderImage(images[2], 600, 400, startIdx + 2)}</div>
          </>
        )}
      </div>
    );

    if (group.length === 1) {
      return <div className="w-full h-96 p-1">
        {renderImage(group[0], 1200, 800, startIndex)}
      </div>;
    }

    if (group.length === 2) {
      return (
        <>
          {renderLargeImage(group[0], startIndex)}
          {renderLargeImage(group[1], startIndex + 1)}
        </>
      );
    }

    if (isOdd) {
      const smallImages = group.length === 3 ? [group[0], group[2]] : [group[0], group[1], group[3]];
      const largeImage = group.length === 3 ? group[1] : group[2];

      return (
        <>
          {renderSmallImages(smallImages, startIndex)}
          {largeImage && renderLargeImage(largeImage, startIndex + 2)}
        </>
      );
    } else {
      return (
        <>
          {renderLargeImage(group[0], startIndex)}
          {renderSmallImages(group.slice(1), startIndex + 1)}
        </>
      );
    }
  }, [renderImage]);

  return (
    <div className="container mx-auto">
      {imageGroups.map((group, groupIndex) => (
        <div key={groupIndex} className="flex -mx-1">
          {renderGroup(group, groupIndex)}
        </div>
      ))}
    </div>
  );
};

export default ImageGallery;