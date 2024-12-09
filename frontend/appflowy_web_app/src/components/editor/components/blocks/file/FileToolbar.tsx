import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import ActionButton from '@/components/editor/components/toolbar/selection-toolbar/actions/ActionButton';
import { FileNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import { downloadFile } from '@/utils/download';
import { OutlinedInput } from '@mui/material';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';
import { ReactComponent as DownloadIcon } from '@/assets/download.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';

import { useReadOnly, useSlateStatic } from 'slate-react';

function FileToolbar({ node }: {
  node: FileNode
}) {
  const editor = useSlateStatic() as YjsEditor;
  const readOnly = useReadOnly();
  const { t } = useTranslation();
  const url = node.data.url || '';
  const name = node.data.name || '';
  const [open, setOpen] = useState<boolean>(false);
  const [fileName, setFileName] = useState<string>(name);
  const onCopy = async () => {
    await copyTextToClipboard(node.data.url || '');
    notify.success(t('publish.copy.fileBlock'));
  };

  const onDelete = () => {
    CustomEditor.deleteBlock(editor, node.blockId);
  };

  const onDownload = () => {
    if (!url) return;

    void downloadFile(url, name);
  };

  const onUpdateName = () => {
    if (!fileName || fileName === name) return;
    CustomEditor.setBlockData(editor, node.blockId, { name: fileName });
    setOpen(false);
  };

  const inputRef = React.useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    if (!open) {
      inputRef.current = null;
    }
  }, [open]);

  return (
    <div
      onClick={e => e.stopPropagation()}
      className={'absolute z-10 top-2.5 right-2.5'}
    >
      <div className={'flex space-x-1 rounded-[8px] p-1 bg-fill-toolbar shadow border border-line-divider '}>
        <ActionButton
          onClick={onDownload}
          tooltip={t('button.download')}
        >
          <DownloadIcon/>
        </ActionButton>

        <ActionButton
          onClick={onCopy}
          tooltip={t('button.copyLinkOriginal')}
        >
          <CopyIcon/>
        </ActionButton>

        {!readOnly && <>
          <ActionButton
            onClick={() => {
              setOpen(true);
            }}
            tooltip={t('document.plugins.file.renameFile.title')}
          >
            <EditIcon/>
          </ActionButton>
          <ActionButton
            onClick={onDelete}
            tooltip={t('button.delete')}
          >
            <DeleteIcon/>
          </ActionButton>
          <NormalModal
            open={open}
            disableRestoreFocus={true}
            onClose={() => setOpen(false)}
            okText={t('button.save')}
            onOk={onUpdateName}
            title={
              <div
                className={'flex justify-start items-center font-semibold'}>{t('document.plugins.file.renameFile.title')}</div>
            }
          >
            <div className={'flex flex-col gap-2 w-[560px] max-w-full'}>
              <div className={'text-text-caption'}>{t('trash.pageHeader.fileName')}</div>
              <OutlinedInput
                value={fileName}
                fullWidth={true}
                autoFocus={open}
                inputRef={(input: HTMLInputElement) => {
                  if (!input) return;
                  if (!inputRef.current) {
                    setTimeout(() => {
                      input.setSelectionRange(0, input.value.length);
                    }, 50);

                    inputRef.current = input;
                  }
                }}
                onClick={(e) => {
                  if (e.detail > 2) {
                    const target = e.target as HTMLInputElement;

                    // select all text on triple click
                    target.setSelectionRange(0, target.value.length);
                  }
                }}
                onChange={(e) => setFileName(e.target.value)}
                size={'small'}
              />
            </div>
          </NormalModal>
        </>}

      </div>

    </div>
  );
}

export default FileToolbar;