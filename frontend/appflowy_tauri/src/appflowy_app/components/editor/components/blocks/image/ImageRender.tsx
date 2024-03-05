import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ImageNode } from '$app/application/document/document.types';
import { useTranslation } from 'react-i18next';
import { CircularProgress } from '@mui/material';
import { ErrorOutline } from '@mui/icons-material';
import ImageResizer from '$app/components/editor/components/blocks/image/ImageResizer';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import ImageActions from '$app/components/editor/components/blocks/image/ImageActions';

function ImageRender({ selected, node }: { selected: boolean; node: ImageNode }) {
  const [loading, setLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  const imgRef = useRef<HTMLImageElement>(null);
  const editor = useSlateStatic();
  const { url, width: imageWidth } = node.data;
  const { t } = useTranslation();
  const blockId = node.blockId;

  const [showActions, setShowActions] = useState(false);
  const [initialWidth, setInitialWidth] = useState<number | null>(null);

  const handleWidthChange = useCallback(
    (newWidth: number) => {
      CustomEditor.setImageBlockData(editor, node, {
        width: newWidth,
      });
    },
    [editor, node]
  );

  useEffect(() => {
    if (!loading && !hasError && initialWidth === null && imgRef.current) {
      setInitialWidth(imgRef.current.offsetWidth);
    }
  }, [hasError, initialWidth, loading]);

  return (
    <>
      <div
        onMouseEnter={() => {
          setShowActions(true);
        }}
        onMouseLeave={() => {
          setShowActions(false);
        }}
        className={'relative'}
      >
        <img
          ref={imgRef}
          draggable={false}
          loading={'lazy'}
          onLoad={() => {
            setHasError(false);
            setLoading(false);
          }}
          onError={() => {
            setHasError(true);
            setLoading(false);
          }}
          src={url}
          alt={`image-${blockId}`}
          className={'object-cover'}
          style={{ width: loading || hasError ? '0' : imageWidth ?? '100%', opacity: selected ? 0.8 : 1 }}
        />
        {initialWidth && <ImageResizer width={imageWidth ?? initialWidth} onWidthChange={handleWidthChange} />}
        {showActions && <ImageActions node={node} />}
      </div>

      {loading && (
        <div className={'flex h-[48px] w-full items-center justify-center gap-2 rounded bg-gray-100'}>
          <CircularProgress size={24} />
          <div className={'text-text-caption'}>{t('editor.loading')}</div>
        </div>
      )}
      {hasError && (
        <div
          className={
            'flex h-[48px] w-full items-center justify-center gap-2  rounded border border-function-error bg-red-50'
          }
        >
          <ErrorOutline className={'text-function-error'} />
          <div className={'text-function-error'}>{t('editor.imageLoadFailed')}</div>
        </div>
      )}
    </>
  );
}

export default ImageRender;
