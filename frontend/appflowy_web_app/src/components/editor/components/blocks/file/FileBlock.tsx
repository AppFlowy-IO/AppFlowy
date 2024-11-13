import { BlockType } from '@/application/types';
import { ReactComponent as FileIcon } from '@/assets/file_upload.svg';
import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import { EditorElementProps, FileNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import { downloadFile } from '@/utils/download';
import React, { forwardRef, memo, useCallback, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useReadOnly } from 'slate-react';

export const FileBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<FileNode>>(({ node, children, ...attributes }, ref) => {
    const { blockId, data } = node;
    const { url, name } = useMemo(() => data || {}, [data]);
    const readOnly = useReadOnly();
    const emptyRef = useRef<HTMLDivElement>(null);
    const [showToolbar, setShowToolbar] = useState(false);

    const className = useMemo(() => {
      const classList = ['w-full bg-bg-body py-2'];

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
        if (!url) {
          if (emptyRef.current && !readOnly) {
            openPopover(blockId, BlockType.FileBlock, emptyRef.current);
          }

          return;
        }

        await downloadFile(url, name);
        // eslint-disable-next-line
      } catch (e: any) {
        notify.error(e.message);
      }
    }, [url, name, readOnly, openPopover, blockId]);

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
          className={`embed-block p-4`}
        >
          <FileIcon className={'w-6 h-6'} />
          <div
            ref={emptyRef}
            className={'flex-1 flex flex-col gap-2 overflow-hidden text-base font-medium'}
          >
            {url ?
              <>
                <div className={'w-full truncate'}>{name?.trim() || t('document.title.placeholder')}</div>
              </> :
              <div className={'text-text-caption'}>
                {t('web.fileBlock.empty')}
              </div>
            }
          </div>

          {showToolbar && url && (
            <RightTopActionsToolbar
              onDownload={handleClick}
              onCopy={async () => {
                if (!url) return;
                try {
                  await copyTextToClipboard(url);
                  notify.success(t('publish.copy.fileBlock'));
                } catch (_) {
                  // do nothing
                }
              }}
            />
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