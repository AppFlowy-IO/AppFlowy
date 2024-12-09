import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType, FieldURLType, FileBlockData } from '@/application/types';
import FileDropzone from '@/components/_shared/file-dropzone/FileDropzone';
import { notify } from '@/components/_shared/notify';
import { TabPanel, ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import EmbedLink from 'src/components/_shared/image-upload/EmbedLink';
import { FileHandler } from '@/utils/file';

export const MAX_FILE_SIZE = 7 * 1024 * 1024; // 7MB

export function getFileName(url: string) {
  const urlObj = new URL(url);
  const name = urlObj.pathname.split('/').pop();

  return name;
}

function FileBlockPopoverContent({
  blockId,
  onClose,
}: {
  blockId: string;
  onClose: () => void;
}) {

  const editor = useSlateStatic() as YjsEditor;
  const { uploadFile } = useEditorContext();
  const entry = useMemo(() => {
    try {
      return findSlateEntryByBlockId(editor, blockId);
    } catch (e) {
      return null;
    }
  }, [blockId, editor]);

  const { t } = useTranslation();

  const [tabValue, setTabValue] = React.useState('upload');

  const handleTabChange = useCallback((_event: React.SyntheticEvent, newValue: string) => {
    setTabValue(newValue);
  }, []);

  const handleInsertEmbedLink = useCallback((url: string) => {
    CustomEditor.setBlockData(editor, blockId, {
      url,
      name: getFileName(url),
      uploaded_at: Date.now(),
      url_type: FieldURLType.Link,
    } as FileBlockData);
    onClose();
  }, [blockId, editor, onClose]);

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

  const getData = useCallback(async (file: File, remoteUrl?: string) => {
    const data = {
      url: remoteUrl,
      name: file.name,
      uploaded_at: Date.now(),
      url_type: FieldURLType.Upload,
    } as FileBlockData;

    if (!remoteUrl) {
      const fileHandler = new FileHandler();
      const res = await fileHandler.handleFileUpload(file);

      data.retry_local_url = res.id;
    }

    return data;
  }, []);

  const insertFileBlock = useCallback(async (file: File) => {
    const url = await uploadFileRemote(file);
    const data = await getData(file, url);

    CustomEditor.addBelowBlock(editor, blockId, BlockType.FileBlock, data);
  }, [blockId, editor, getData, uploadFileRemote]);

  const handleChangeUploadFiles = useCallback(async (files: File[]) => {
    if (!files.length) return;

    const [file, ...otherFiles] = files;
    const url = await uploadFileRemote(file);
    const data = await getData(file, url);

    CustomEditor.setBlockData(editor, blockId, data);

    for (const file of otherFiles.reverse()) {
      await insertFileBlock(file);
    }

    onClose();
  }, [blockId, editor, getData, insertFileBlock, onClose, uploadFileRemote]);

  const tabOptions = useMemo(() => {
    return [
      {
        key: 'upload',
        label: t('button.upload'),
        panel: <FileDropzone
          multiple={true}
          placeholder={<span>
            {t('document.plugins.file.fileUploadHint')}
            <span className={'text-fill-default'}>{t('document.plugins.photoGallery.browserLayout')}</span>
          </span>}
          onChange={handleChangeUploadFiles}
        />,
      },
      {
        key: 'embed',
        label: t('document.plugins.file.networkTab'),
        panel: <EmbedLink
          onDone={handleInsertEmbedLink}
          defaultLink={(entry?.[0].data as FileBlockData).url}
          placeholder={t('document.plugins.file.networkHint')}
        />,
      },
    ];
  }, [entry, handleChangeUploadFiles, handleInsertEmbedLink, t]);

  const selectedIndex = tabOptions.findIndex((tab) => tab.key === tabValue);

  return (
    <div className={'flex flex-col p-2 gap-2'}>
      <ViewTabs
        value={tabValue}
        onChange={handleTabChange}
        className={'min-h-[38px] px-2 border-b border-line-divider w-[560px] max-w-[964px]'}
      >
        {tabOptions.map((tab) => {
          const { key, label } = tab;

          return <ViewTab
            key={key}
            iconPosition="start"
            color="inherit"
            label={label}
            value={key}
          />;
        })}
      </ViewTabs>
      {tabOptions.map((tab, index) => {
        const { key, panel } = tab;

        return (
          <TabPanel
            className={'flex h-full w-full flex-col'}
            key={key}
            index={index}
            value={selectedIndex}
          >
            {panel}
          </TabPanel>
        );
      })}
    </div>
  );
}

export default FileBlockPopoverContent;