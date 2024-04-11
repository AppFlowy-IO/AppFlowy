import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { ImageNode, ImageType } from '$app/application/document/document.types';
import { useTranslation } from 'react-i18next';
import { CircularProgress } from '@mui/material';
import { ErrorOutline } from '@mui/icons-material';
import ImageResizer from '$app/components/editor/components/blocks/image/ImageResizer';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import ImageActions from '$app/components/editor/components/blocks/image/ImageActions';
import { LocalImage } from '$app/components/_shared/image_upload';
import debounce from 'lodash-es/debounce';

const MIN_WIDTH = 100;

const DELAY = 300;

function ImageRender({ selected, node }: { selected: boolean; node: ImageNode }) {
  const [loading, setLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  const imgRef = useRef<HTMLImageElement>(null);
  const editor = useSlateStatic();
  const { url = '', width: imageWidth, image_type: source } = useMemo(() => node.data || {}, [node.data]);
  const { t } = useTranslation();
  const blockId = node.blockId;

  const [showActions, setShowActions] = useState(false);
  const [initialWidth, setInitialWidth] = useState<number | null>(null);
  const [newWidth, setNewWidth] = useState<number | null>(imageWidth ?? null);

  const debounceSubmitWidth = useMemo(() => {
    return debounce((newWidth: number) => {
      CustomEditor.setImageBlockData(editor, node, {
        width: newWidth,
      });
    }, DELAY);
  }, [editor, node]);

  const handleWidthChange = useCallback(
    (newWidth: number) => {
      setNewWidth(newWidth);
      debounceSubmitWidth(newWidth);
    },
    [debounceSubmitWidth]
  );

  useEffect(() => {
    if (!loading && !hasError && initialWidth === null && imgRef.current) {
      setInitialWidth(imgRef.current.offsetWidth);
    }
  }, [hasError, initialWidth, loading]);
  const imageProps: React.ImgHTMLAttributes<HTMLImageElement> = useMemo(() => {
    return {
      style: { width: loading || hasError ? '0' : newWidth ?? '100%', opacity: selected ? 0.8 : 1 },
      className: 'object-cover',
      ref: imgRef,
      src: url,
      draggable: false,
      onLoad: () => {
        setHasError(false);
        setLoading(false);
      },
      onError: () => {
        setHasError(true);
        setLoading(false);
      },
    };
  }, [url, newWidth, loading, hasError, selected]);

  const renderErrorNode = useCallback(() => {
    return (
      <div
        className={'flex h-full w-full items-center justify-center gap-2 rounded border border-function-error bg-red-50'}
      >
        <ErrorOutline className={'text-function-error'} />
        <div className={'text-function-error'}>{t('editor.imageLoadFailed')}</div>
      </div>
    );
  }, [t]);

  if (!url) return null;

  return (
    <div
      onMouseEnter={() => {
        setShowActions(true);
      }}
      onMouseLeave={() => {
        setShowActions(false);
      }}
      style={{
        minWidth: MIN_WIDTH,
        width: 'fit-content',
      }}
      className={`image-render relative min-h-[48px] ${
        hasError || (loading && source !== ImageType.Local) ? 'w-full' : ''
      }`}
    >
      {source === ImageType.Local ? (
        <LocalImage
          {...imageProps}
          renderErrorNode={() => {
            setHasError(true);
            return null;
          }}
          loading={'lazy'}
        />
      ) : (
        <img loading={'lazy'} {...imageProps} alt={`image-${blockId}`} />
      )}

      {initialWidth && (
        <>
          <ImageResizer
            isLeft
            minWidth={MIN_WIDTH}
            width={imageWidth ?? initialWidth}
            onWidthChange={handleWidthChange}
          />
          <ImageResizer minWidth={MIN_WIDTH} width={imageWidth ?? initialWidth} onWidthChange={handleWidthChange} />
        </>
      )}
      {showActions && <ImageActions node={node} />}
      {hasError ? (
        renderErrorNode()
      ) : loading && source !== ImageType.Local ? (
        <div className={'flex h-full w-full items-center justify-center gap-2 rounded bg-gray-100'}>
          <CircularProgress size={24} />
          <div className={'text-text-caption'}>{t('editor.loading')}</div>
        </div>
      ) : null}
    </div>
  );
}

export default ImageRender;
