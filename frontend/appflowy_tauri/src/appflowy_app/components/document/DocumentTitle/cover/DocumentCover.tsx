import React, { useCallback, useEffect, useState } from 'react';
import ChangeCoverButton from '$app/components/document/DocumentTitle/cover/ChangeCoverButton';
import { readImage } from '$app/utils/document/image';

function DocumentCover({
  cover,
  coverType,
  className,
  onUpdateCover,
}: {
  cover?: string;
  coverType?: 'image' | 'color';
  className?: string;
  onUpdateCover: (coverType: 'image' | 'color' | '', cover: string) => void;
}) {
  const [hover, setHover] = useState(false);
  const [leftOffset, setLeftOffset] = useState(0);
  const [width, setWidth] = useState(0);
  const [coverSrc, setCoverSrc] = useState<string | undefined>();
  const calcLeftOffset = useCallback(() => {
    const docBody = document.getElementById('appflowy-block-doc') as HTMLElement;

    if (!docBody) {
      setLeftOffset(0);
      return;
    }

    const bodyRect = docBody.getBoundingClientRect();

    setWidth(bodyRect.width);
    const docOffsetLeft = bodyRect.left;
    const docTitle = document.querySelector('.doc-title') as HTMLElement;

    if (!docTitle) {
      setLeftOffset(0);
      return;
    }

    const titleOffsetLeft = docTitle.getBoundingClientRect().left;

    setLeftOffset(titleOffsetLeft - docOffsetLeft);
  }, []);

  useEffect(() => {
    calcLeftOffset();
    window.addEventListener('resize', calcLeftOffset);
    return () => {
      window.removeEventListener('resize', calcLeftOffset);
    };
  }, [calcLeftOffset]);

  useEffect(() => {
    if (coverType === 'image' && cover) {
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
      {coverType === 'image' && <img src={coverSrc} className={'h-full w-full object-cover'} />}
      {coverType === 'color' && <div className={'h-full w-full'} style={{ backgroundColor: cover }} />}
      <ChangeCoverButton onUpdateCover={onUpdateCover} visible={hover} cover={cover} coverType={coverType} />
    </div>
  );
}

export default React.memo(DocumentCover);
