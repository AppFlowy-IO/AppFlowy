import { EditorElementProps, LinkPreviewNode } from '@/components/editor/editor.type';
import axios from 'axios';
import React, { forwardRef, memo, useEffect, useState } from 'react';
import { useReadOnly } from 'slate-react';
import emptyImageSrc from '@/assets/images/empty.png';

export const LinkPreview = memo(
  forwardRef<HTMLDivElement, EditorElementProps<LinkPreviewNode>>(({ node, children, ...attributes }, ref) => {
    const [data, setData] = useState<{
      image: { url: string };
      title: string;
      description: string;
    } | null>(null);
    const [notFound, setNotFound] = useState<boolean>(false);
    const url = node.data.url;

    useEffect(() => {
      if (!url) return;

      setData(null);
      void (async () => {
        try {
          setNotFound(false);
          const response = await axios.get(`https://api.microlink.io/?url=${url}`);

          if (response.data.statusCode !== 200) {
            setNotFound(true);
            return;
          }

          const data = response.data.data;

          setData(data);
        } catch (_) {
          setNotFound(true);
        }
      })();
    }, [url]);
    const readOnly = useReadOnly();

    return (
      <div
        onClick={() => {
          window.open(url, '_blank');
        }}
        contentEditable={readOnly ? false : undefined}
        {...attributes}
        ref={ref}
        className={`link-preview-block relative w-full cursor-pointer`}
      >
        <div
          className={
            'embed-block p-4 items-center'
          }
          contentEditable={false}
        >
          {notFound ? (
            <div className={'flex w-full items-center'}>
              <div
                className={'text-text-title min-w-[80px] w-[120px] flex items-center justify-center mr-2 h-[80px] border rounded'}>
                <img src={emptyImageSrc} alt={'Empty state'} className={'h-full object-center object-cover'}/>
              </div>
              <div className={'flex-1 flex flex-col'}>
                <div className={'text-function-error'}>
                  The link cannot be previewed. Click to open in a new tab.
                </div>
                <div className={'text-sm text-text-caption'}>
                  {url}
                </div>
              </div>

            </div>
          ) : (
            <>
              <img
                src={data?.image.url}
                alt={data?.title}
                className={'container h-full min-h-[48px] w-[25%] rounded bg-cover bg-center'}
              />
              <div className={'flex flex-col justify-center gap-2 overflow-hidden'}>
                <div
                  className={
                    'max-h-[48px] overflow-hidden whitespace-pre-wrap break-words text-base font-bold text-text-title'
                  }
                >
                  {data?.title}
                </div>
                <div
                  className={
                    'max-h-[64px] overflow-hidden truncate whitespace-pre-wrap break-words text-sm text-text-title'
                  }
                >
                  {data?.description}
                </div>
                <div className={'truncate whitespace-nowrap text-xs text-text-caption'}>{url}</div>
              </div>
            </>
          )}
        </div>
        <div
          ref={ref}
          className={'absolute left-0 top-0 h-full w-full caret-transparent'}
        >
          {children}
        </div>
      </div>
    );
  }),
  (prev, next) => prev.node.data.url === next.node.data.url);
export default LinkPreview;
