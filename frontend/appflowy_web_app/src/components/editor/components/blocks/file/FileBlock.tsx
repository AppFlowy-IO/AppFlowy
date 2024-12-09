import { BlockType, FieldURLType, FileBlockData } from '@/application/types';
import { ReactComponent as FileIcon } from '@/assets/file_upload.svg';
import { ReactComponent as ReloadIcon } from '@/assets/reload.svg';

import { notify } from '@/components/_shared/notify';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import FileToolbar from '@/components/editor/components/blocks/file/FileToolbar';
import { EditorElementProps, FileNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useReadOnly, useSlateStatic } from 'slate-react';
import { openUrl } from '@/utils/url';
import { IconButton, Tooltip } from '@mui/material';
import { MAX_FILE_SIZE } from '@/components/editor/components/block-popover/FileBlockPopoverContent';
import { useEditorContext } from '@/components/editor/EditorContext';
import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { FileHandler } from '@/utils/file';

export const FileBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<FileNode>>(({ node, children, ...attributes }, ref) => {
    const { blockId, data } = node;
    const { uploadFile } = useEditorContext();
    const editor = useSlateStatic() as YjsEditor;
    const [needRetry, setNeedRetry] = useState(false);
    const fileHandler = useMemo(() => new FileHandler(), []);
    const [localUrl, setLocalUrl] = useState<string | undefined>(undefined);

    const { url, name, retry_local_url } = useMemo(() => data || {}, [data]);
    const readOnly = useReadOnly();
    const emptyRef = useRef<HTMLDivElement>(null);
    const [showToolbar, setShowToolbar] = useState(false);

    const className = useMemo(() => {
      const classList = ['w-full'];

      if (url) {
        classList.push('cursor-pointer');
      } else {
        classList.push('text-text-caption');
      }

      if (attributes.className) {
        classList.push(attributes.className);
      }

      if (!readOnly) {
        classList.push('cursor-pointer');
      }

      return classList.join(' ');
    }, [attributes.className, readOnly, url]);

    const { t } = useTranslation();
    const {
      openPopover,
    } = usePopoverContext();

    const handleClick = useCallback(async () => {
      try {
        if (!url && !needRetry) {
          if (emptyRef.current && !readOnly) {
            openPopover(blockId, BlockType.FileBlock, emptyRef.current);
          }

          return;
        }

        const link = url || localUrl;

        if (link) {
          void openUrl(link, '_blank');
        }
        // eslint-disable-next-line
      } catch (e: any) {
        notify.error(e.message);
      }
    }, [url, needRetry, localUrl, readOnly, openPopover, blockId]);

    useEffect(() => {
      void (async () => {
        if (retry_local_url) {
          const fileData = await fileHandler.getStoredFile(retry_local_url);

          setLocalUrl(fileData?.url);
          setNeedRetry(!!fileData);
        } else {
          setNeedRetry(false);
        }
      })();
    }, [retry_local_url, fileHandler]);

    const uploadFileRemote = useCallback(async (file: File) => {
      if (file.size > MAX_FILE_SIZE) {
        notify.error(`File size is too large, please upload a file less than ${MAX_FILE_SIZE / 1024 / 1024}MB`);

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

      await fileHandler.cleanup(retry_local_url);
      CustomEditor.setBlockData(editor, blockId, {
        url,
        name,
        uploaded_at: Date.now(),
        url_type: FieldURLType.Upload,
        retry_local_url: '',
      } as FileBlockData);
    }, [blockId, editor, fileHandler, name, retry_local_url, uploadFileRemote]);

    return (
      <div
        {...attributes}
        contentEditable={readOnly ? false : undefined}
        className={className}
        onMouseEnter={() => {
          if (!url) return;
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
        onClick={handleClick}
      >
        <div
          contentEditable={false}
          className={`embed-block items-center p-4`}
        >
          <FileIcon className={'w-6 h-6'}/>
          <div
            ref={emptyRef}
            className={'flex-1 flex flex-col gap-2 overflow-hidden text-base font-medium'}
          >
            {url || needRetry ?
              <div className={'flex flex-col gap-2'}>
                <div className={'w-full truncate'}>{name?.trim() || t('document.title.placeholder')}</div>
                {needRetry &&
                  <div className={'text-function-error font-normal'}>{t('web.fileBlock.uploadFailed')}</div>}
              </div> :
              <div className={'text-text-caption'}>
                {t('web.fileBlock.empty')}
              </div>
            }
          </div>

          {needRetry && (
            <Tooltip placement={'top'} title={t('web.fileBlock.retry')}>
              <IconButton onClick={handleRetry} size={'small'} color={'error'}>
                <ReloadIcon/>
              </IconButton>
            </Tooltip>

          )}
          {showToolbar && url && (
            <FileToolbar node={node}/>
          )}
        </div>
        <div
          ref={ref}
          className={`absolute h-full w-full caret-transparent`}
        >
          {children}
        </div>

      </div>
    );
  }));

export default FileBlock;