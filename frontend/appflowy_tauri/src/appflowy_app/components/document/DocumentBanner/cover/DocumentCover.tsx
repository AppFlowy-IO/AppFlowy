import React, { useCallback, useEffect, useState } from 'react';
import ChangeCoverButton from '$app/components/document/DocumentBanner/cover/ChangeCoverButton';
import { readImage } from '$app/utils/document/image';
import { CoverType } from '$app/interfaces/document';

function DocumentCover({
  cover,
  coverType,
  className,
  onUpdateCover,
}: {
  cover?: string;
  coverType?: CoverType;
  className?: string;
  onUpdateCover: (coverType: CoverType | null, cover: string | null) => void;
}) {
  const [hover, setHover] = useState(false);
  const [leftOffset, setLeftOffset] = useState(0);
  const [width, setWidth] = useState(0);
  const [coverSrc, setCoverSrc] = useState<string | undefined>();
  const calcLeftOffset = useCallback((bodyOffsetLeft: number) => {
    const docTitle = document.querySelector('.doc-title') as HTMLElement;

    if (!docTitle) {
      setLeftOffset(0);
      return;
    }

    const titleOffsetLeft = docTitle.getBoundingClientRect().left;

    setLeftOffset(titleOffsetLeft - bodyOffsetLeft);
  }, []);

  const handleWidthChange: ResizeObserverCallback = useCallback(
    (entries) => {
      entries.forEach((entry) => {
        const { width } = entry.contentRect;

        setWidth(width);
        const left = entry.target.getBoundingClientRect().left;

        calcLeftOffset(left);
      });
    },
    [calcLeftOffset]
  );

  useEffect(() => {
    const observer = new ResizeObserver(handleWidthChange);
    const docPage = document.getElementById('appflowy-block-doc') as HTMLElement;

    observer.observe(docPage);
    return () => {
      observer.disconnect();
    };
  }, [handleWidthChange]);

  useEffect(() => {
    if (coverType === CoverType.Image && cover) {
      void (async () => {
        const src = await readImage(cover);

        setCoverSrc(src);
      })();
    }
  }, [cover, coverType]);

  if (!cover || !coverType) return null;
  return (
    <div
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        left: -leftOffset,
        width,
      }}
      className={`absolute top-0 w-full overflow-hidden ${className}`}
    >
      {coverType === CoverType.Image ? (
        <img src={coverSrc} className={'h-full w-full object-cover'} />
      ) : (
        <div className={'h-full w-full'} style={{ backgroundColor: cover }} />
      )}
      <ChangeCoverButton onUpdateCover={onUpdateCover} visible={hover} cover={cover} coverType={coverType} />
    </div>
  );
}

export default React.memo(DocumentCover);
