import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType, ImageBlockData, ImageType } from '@/application/types';
import { ALLOWED_IMAGE_EXTENSIONS, MAX_IMAGE_SIZE, Unsplash } from '@/components/_shared/image-upload';
import EmbedLink from '@/components/_shared/image-upload/EmbedLink';
import { TabPanel, ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { notify } from '@/components/_shared/notify';
import { FileHandler } from '@/utils/file';
import FileDropzone from '@/components/_shared/file-dropzone/FileDropzone';

function ImageBlockPopoverContent({
  blockId,
  onClose,
}: {
  blockId: string;
  onClose: () => void;
}) {

  const { uploadFile } = useEditorContext();
  const editor = useSlateStatic() as YjsEditor;

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

  const handleUpdateLink = useCallback((url: string, type?: ImageType) => {
    CustomEditor.setBlockData(editor, blockId, {
      url,
      image_type: type || ImageType.External,
    } as ImageBlockData);
    onClose();
  }, [blockId, editor, onClose]);

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

  const getData = useCallback(async (file: File, remoteUrl?: string) => {
    const data = {
      url: remoteUrl,
      image_type: ImageType.External,
    } as ImageBlockData;

    if (!remoteUrl) {
      const fileHandler = new FileHandler();
      const res = await fileHandler.handleFileUpload(file);

      data.retry_local_url = res.id;
    }

    return data;
  }, []);

  const insertImageBlock = useCallback(async (file: File) => {
    const url = await uploadFileRemote(file);
    const data = await getData(file, url);

    CustomEditor.addBelowBlock(editor, blockId, BlockType.ImageBlock, data);
  }, [blockId, editor, getData, uploadFileRemote]);

  const handleChangeUploadFiles = useCallback(async (files: File[]) => {
    if (!files.length) return;

    const [file, ...otherFiles] = files;
    const url = await uploadFileRemote(file);
    const data = await getData(file, url);

    CustomEditor.setBlockData(editor, blockId, data);

    for (const file of otherFiles.reverse()) {
      await insertImageBlock(file);
    }

    onClose();
  }, [blockId, editor, getData, insertImageBlock, onClose, uploadFileRemote]);

  const tabOptions = useMemo(() => {
    return [
      {
        key: 'upload',
        label: t('button.upload'),
        panel: <FileDropzone
          multiple={true}
          onChange={handleChangeUploadFiles}
          accept={ALLOWED_IMAGE_EXTENSIONS.join(',')}
        />,
      },
      {
        key: 'embed',
        label: t('document.plugins.file.networkTab'),
        panel: <EmbedLink
          onDone={handleUpdateLink}
          defaultLink={(entry?.[0].data as ImageBlockData).url}
          placeholder={t('document.imageBlock.embedLink.placeholder')}
        />,
      },
      {
        key: 'unsplash',
        label: t('pageStyle.unsplash'),
        panel: <Unsplash onDone={handleUpdateLink}/>,
      },
    ];
  }, [entry, handleChangeUploadFiles, handleUpdateLink, t]);

  const selectedIndex = tabOptions.findIndex((tab) => tab.key === tabValue);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    const handleResize = () => {
      const top = el.getBoundingClientRect().top;
      const height = window.innerHeight - top - 30;

      el.style.maxHeight = `${height}px`;
    };

    if (tabValue === 'unsplash') {
      handleResize();
    }

  }, [tabValue]);

  return (
    <div className={'flex flex-col p-2'}>
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
      <div
        ref={ref}
        className={'pt-4 appflowy-scroller max-h-[400px] overflow-y-auto'}
      >
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

    </div>
  );
}

export default ImageBlockPopoverContent;