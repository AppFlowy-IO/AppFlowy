import { EditorElementProps, LinkPreviewNode } from '@/components/editor/editor.type';
import axios from 'axios';
import React, { forwardRef, memo, useEffect, useState } from 'react';

export const LinkPreview = memo(
  forwardRef<HTMLDivElement, EditorElementProps<LinkPreviewNode>>(({ node, children, ...attributes }, ref) => {
    const [data, setData] = useState<{
      image: { url: string };
      title: string;
      description: string;
    } | null>(null);
    const url = node.data.url;

    useEffect(() => {
      if (!url) return;

      setData(null);
      void (async () => {
        try {
          const response = await axios.get(`https://api.microlink.io/?url=${url}`);

          if (response.data.statusCode !== 200) return;
          const data = response.data.data;

          setData(data);
        } catch (error) {
          // don't do anything
        }
      })();
    }, [url]);
    return (
      <div
        onClick={() => {
          window.open(url, '_blank');
        }}
        {...attributes}
        ref={ref}
        className={`link-preview-block relative w-full cursor-pointer`}
      >
        <div>
          {data ? (
            <div
              className={
                'container-bg flex w-full cursor-pointer select-none items-center gap-4 rounded border border-line-divider bg-fill-list-active p-3'
              }
            >
              <img
                src={data.image.url}
                alt={data.title}
                className={'container h-full w-40 rounded bg-cover bg-center'}
              />
              <div className={'flex flex-col justify-center gap-2'}>
                <div className={'text-base font-bold text-text-title'}>{data.title}</div>
                <div className={'text-sm text-text-caption'}>{data.description}</div>
              </div>
            </div>
          ) : (
            <a href={node.data.url} className={'text-content-blue-400 underline'} target={'blank'}>
              {node.data.url}
            </a>
          )}
        </div>
        <div ref={ref} className={'absolute left-0 top-0 h-full w-full caret-transparent'}>
          {children}
        </div>
      </div>
    );
  })
);
export default LinkPreview;
