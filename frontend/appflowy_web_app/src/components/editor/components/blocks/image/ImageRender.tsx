import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { ImageBlockNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Skeleton } from '@mui/material';
import { ReactComponent as ErrorOutline } from '@/assets/error.svg';

const MIN_WIDTH = 100;

function ImageRender({
  selected,
  node,
  showToolbar,
}: {
  selected: boolean;
  node: ImageBlockNode;
  showToolbar?: boolean;
}) {
  const [loading, setLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  const imgRef = useRef<HTMLImageElement>(null);
  const { url = '', width: imageWidth } = useMemo(() => node.data || {}, [node.data]);
  const { t } = useTranslation();
  const blockId = node.blockId;
  const [initialWidth, setInitialWidth] = useState<number | null>(null);
  const [newWidth] = useState<number | null>(imageWidth ?? null);

  useEffect(() => {
    if (!loading && !hasError && initialWidth === null && imgRef.current) {
      setInitialWidth(imgRef.current.offsetWidth);
    }
  }, [hasError, initialWidth, loading]);
  const imageProps: React.ImgHTMLAttributes<HTMLImageElement> = useMemo(() => {
    return {
      style: {
        width: loading || hasError ? '0' : newWidth ?? '100%',
        opacity: selected ? 0.8 : 1,
        height: hasError ? 0 : 'auto',
      },
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
        className={
          'flex h-[48px] w-full items-center justify-center gap-2 rounded border border-function-error bg-red-50'
        }
      >
        <ErrorOutline className={'text-function-error'} />
        <div className={'text-function-error'}>{t('editor.imageLoadFailed')}</div>
      </div>
    );
  }, [t]);

  if (!url) return null;

  return (
    <div
      style={{
        minWidth: MIN_WIDTH,
        width: loading || hasError ? '100%' : 'fit-content',
      }}
      className={`image-render relative min-h-[48px] ${hasError ? 'w-full' : ''}`}
    >
      <img loading={'lazy'} {...imageProps} alt={`image-${blockId}`} />
      {showToolbar && url && (
        <RightTopActionsToolbar
          onCopy={async () => {
            if (!url) return;
            try {
              await copyTextToClipboard(url);
              notify.success(t('publish.copy.imageBlock'));
            } catch (_) {
              // do nothing
            }
          }}
        />
      )}
      {hasError ? renderErrorNode() : loading ? <Skeleton variant='rounded' width={'100%'} height={200} /> : null}
    </div>
  );
}

export default ImageRender;
