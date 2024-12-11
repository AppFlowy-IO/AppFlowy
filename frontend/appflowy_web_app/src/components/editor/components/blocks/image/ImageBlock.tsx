import { AlignType, BlockType, ImageBlockData, ImageType } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import { EditorElementProps, ImageBlockNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { ReactEditor, useReadOnly, useSelected, useSlateStatic } from 'slate-react';
import ImageEmpty from './ImageEmpty';
import ImageRender from './ImageRender';
import { useEditorContext } from '@/components/editor/EditorContext';
import { YjsEditor } from '@/application/slate-yjs';
import { FileHandler } from '@/utils/file';
import { CustomEditor } from '@/application/slate-yjs/command';
import { MAX_IMAGE_SIZE } from '@/components/_shared/image-upload';
import { useTranslation } from 'react-i18next';
import { ReactComponent as ErrorIcon } from '@/assets/error.svg';
import { CircularProgress } from '@mui/material';

export const ImageBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ImageBlockNode>>(({
    node,
    children,
    ...attributes
  }, ref) => {
    const { t } = useTranslation();

    const { blockId, data } = node;
    const retry_local_url = data?.retry_local_url;
    const { uploadFile } = useEditorContext();
    const editor = useSlateStatic() as YjsEditor;
    const [needRetry, setNeedRetry] = useState(false);
    const [localUrl, setLocalUrl] = useState<string | undefined>(undefined);
    const [loading, setLoading] = useState(false);

    const fileHandler = useMemo(() => new FileHandler(), []);
    const readOnly = useReadOnly();
    const selected = useSelected();
    const { url, align } = useMemo(() => data || {}, [data]);
    const containerRef = useRef<HTMLDivElement>(null);
    const onFocusNode = useCallback(() => {
      ReactEditor.focus(editor);
      const path = ReactEditor.findPath(editor, node);

      editor.select(path);
    }, [editor, node]);

    const className = useMemo(() => {
      const classList = ['w-full'];

      if (!readOnly) {
        classList.push('cursor-pointer');
      }

      if (attributes.className) {
        classList.push(attributes.className);
      }

      return classList.join(' ');
    }, [attributes.className, readOnly]);

    const alignCss = useMemo(() => {
      if (!align) return '';

      return align === AlignType.Center ? 'justify-center' : align === AlignType.Right ? 'justify-end' : 'justify-start';
    }, [align]);
    const [showToolbar, setShowToolbar] = useState(false);
    const {
      openPopover,
    } = usePopoverContext();

    const handleClick = useCallback(async () => {
      try {
        if (!url && !needRetry) {
          if (containerRef.current && !readOnly) {
            openPopover(blockId, BlockType.ImageBlock, containerRef.current);
          }

          return;
        }

        // eslint-disable-next-line
      } catch (e: any) {
        notify.error(e.message);
      }
    }, [needRetry, url, readOnly, openPopover, blockId]);

    useEffect(() => {
      if (readOnly) return;
      void (async () => {
        if (retry_local_url) {
          const fileData = await fileHandler.getStoredFile(retry_local_url);

          setLocalUrl(fileData?.url);
          setNeedRetry(!!fileData);
        } else {
          setNeedRetry(false);
        }
      })();
    }, [readOnly, retry_local_url, fileHandler]);

    const uploadFileRemote = useCallback(async (file: File) => {
      if (file.size > MAX_IMAGE_SIZE) {
        notify.error(`Image size is too large, please upload a file less than ${MAX_IMAGE_SIZE / 1024 / 1024}MB`);

        return;
      }

      try {
        if (uploadFile) {
          return await uploadFile(file);
        }
        // eslint-disable-next-line
      } catch (e: any) {
        return;
      }
    }, [uploadFile]);

    const handleRetry = useCallback(async (e: React.MouseEvent) => {
      e.stopPropagation();
      if (!retry_local_url) return;
      const fileData = await fileHandler.getStoredFile(retry_local_url);
      const file = fileData?.file;

      if (!file) return;

      const url = await uploadFileRemote(file);

      if (!url) {
        return;
      }

      setLoading(true);
      try {
        await fileHandler.cleanup(retry_local_url);
        CustomEditor.setBlockData(editor, blockId, {
          url,
          image_type: ImageType.External,
          retry_local_url: '',
        } as ImageBlockData);
      } catch (e) {
        // do noting
      } finally {
        setLoading(false);
      }
    }, [blockId, editor, fileHandler, retry_local_url, uploadFileRemote]);

    return (
      <div
        {...attributes}
        ref={containerRef}
        contentEditable={readOnly ? false : undefined}
        onMouseEnter={() => {
          if (!url) return;
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
        className={className}
        onClick={handleClick}
      >

        <div
          contentEditable={false}
          className={`embed-block relative ${alignCss} ${(url || needRetry) ? '!bg-transparent !border-none !rounded-none' : 'p-4'}`}
        >
          {url || needRetry ? (
            <ImageRender
              showToolbar={showToolbar}
              selected={selected}
              node={node}
              localUrl={localUrl}
            />
          ) : (
            <ImageEmpty
              node={node}
              onEscape={onFocusNode}
              containerRef={containerRef}
            />
          )}
          {needRetry && <div className={'absolute right-4 bottom-2 flex items-center gap-2'}>
            <ErrorIcon className={'w-4 h-4 text-function-error'}/>
            <div className={'font-normal'}>{t('button.uploadFailed')}</div>
            {loading ? <CircularProgress size={16}/> :
              <button onClick={handleRetry} className={'hover:underline text-fill-default'}>
                {t('button.retry')}
              </button>}
          </div>}
        </div>
        <div
          ref={ref}
          className={'absolute left-0 top-0 h-full w-full select-none caret-transparent'}
        >
          {children}
        </div>
      </div>
    );
  }),
);

export default ImageBlock;
