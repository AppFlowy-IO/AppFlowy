import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { EditorElementProps, FileNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import { downloadFile } from '@/utils/download';
import React, { forwardRef, memo, useCallback, useMemo, useState } from 'react';
import { ReactComponent as FileIcon } from '@/assets/file_upload.svg';
import { useTranslation } from 'react-i18next';

export const FileBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<FileNode>>(({ node, children, ...attributes }, ref) => {
    const { url, name } = useMemo(() => node.data || {}, [node.data]);

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

      return classList.join(' ');
    }, [attributes.className, url]);
    const [showToolbar, setShowToolbar] = useState(false);
    const { t } = useTranslation();

    const handleDownload = useCallback(async () => {
      try {
        if (!url) return;
        await downloadFile(url, name);
        // eslint-disable-next-line
      } catch (e: any) {
        notify.error(e.message);
      }
    }, [url, name]);

    return (
      <div
        {...attributes}
        contentEditable={false}
        className={className}
        onMouseEnter={() => {
          if (!url) return;
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
        onClick={handleDownload}
      >
        <div
          contentEditable={false}
          className={'flex relative w-full gap-4 overflow-hidden px-4 rounded-[8px] border border-line-divider bg-fill-list-active py-4'}
        >
          <FileIcon className={'w-6 h-6'} />
          <div className={'flex-1 flex flex-col gap-2 overflow-hidden text-base font-medium'}>
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
              onDownload={handleDownload}
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