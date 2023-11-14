import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Align, BlockType, NestedBlock } from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { Log } from '$app/utils/log';
import { getNode } from '$app/utils/document/node';
import { readImage } from '$app/utils/document/image';

export function useImageBlock(node: NestedBlock<BlockType.ImageBlock>) {
  const { url, width, align, height } = node.data;
  const dispatch = useAppDispatch();
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<boolean>(false);
  const { controller } = useSubscribeDocument();
  const [resizing, setResizing] = useState<boolean>(false);
  const startResizePoint = useRef<{
    left: boolean;
    x: number;
    y: number;
  }>();
  const startResizeWidth = useRef<number>(0);

  const [src, setSrc] = useState<string>('');
  const [displaySize, setDisplaySize] = useState<{
    width: number;
    height: number;
  }>({
    width: width || 0,
    height: height || 0,
  });

  const onResizeStart = useCallback(
    (e: React.MouseEvent<HTMLDivElement>, left: boolean) => {
      e.preventDefault();
      e.stopPropagation();
      setResizing(true);
      startResizeWidth.current = displaySize.width;
      startResizePoint.current = {
        x: e.clientX,
        y: e.clientY,
        left,
      };
    },
    [displaySize.width]
  );

  const updateWidth = useCallback(
    (width: number, height: number) => {
      void dispatch(
        updateNodeDataThunk({
          id: node.id,
          data: {
            width,
            height,
          },
          controller,
        })
      );
    },
    [controller, dispatch, node.id]
  );

  useEffect(() => {
    const currentSize: {
      width?: number;
      height?: number;
    } = {};
    const onResize = (e: MouseEvent) => {
      const clientX = e.clientX;

      if (!startResizePoint.current) return;
      const { x, left } = startResizePoint.current;
      const startWidth = startResizeWidth.current || 0;
      const diff = (left ? x - clientX : clientX - x) / 2;

      setDisplaySize((prevState) => {
        const displayWidth = prevState?.width || 0;
        const displayHeight = prevState?.height || 0;
        const ratio = displayWidth / displayHeight;

        const width = startWidth + diff;
        const height = width / ratio;

        Object.assign(currentSize, {
          width,
          height,
        });
        return {
          width,
          height,
        };
      });
    };

    const onResizeEnd = () => {
      setResizing(false);
      if (!startResizePoint.current) return;
      startResizePoint.current = undefined;
      if (!currentSize.width || !currentSize.height) return;
      updateWidth(Math.floor(currentSize.width) || 0, Math.floor(currentSize.height) || 0);
    };

    if (resizing) {
      document.addEventListener('mousemove', onResize);
      document.addEventListener('mouseup', onResizeEnd);
    } else {
      document.removeEventListener('mousemove', onResize);
      document.removeEventListener('mouseup', onResizeEnd);
    }
  }, [resizing, updateWidth]);

  const alignSelf = useMemo(() => {
    if (align === Align.Left) return 'flex-start';
    if (align === Align.Right) return 'flex-end';
    return 'center';
  }, [align]);

  useEffect(() => {
    if (!url) return;
    const image = new Image();

    setLoading(true);
    setError(false);
    image.onload = function () {
      const ratio = image.width / image.height;
      const element = getNode(node.id) as HTMLDivElement;

      if (!element) return;
      const maxWidth = element.offsetWidth || 1000;
      const imageWidth = Math.min(image.width, maxWidth);

      setDisplaySize((prevState) => {
        if (prevState.width <= 0) {
          return {
            width: imageWidth,
            height: imageWidth / ratio,
          };
        }

        return prevState;
      });

      setLoading(false);
    };

    image.onerror = function () {
      setLoading(false);
      setError(true);
    };

    const isRemote = url.startsWith('http');

    if (isRemote) {
      setSrc(url);
      image.src = url;
      return;
    }

    void (async () => {
      setError(false);
      try {
        const src = await readImage(url);

        setSrc(src);
        image.src = src;
      } catch (e) {
        Log.error(e);
        setError(true);
      }
    })();
  }, [node.id, url]);

  return {
    displaySize,
    src,
    alignSelf,
    onResizeStart,
    loading,
    error,
  };
}
