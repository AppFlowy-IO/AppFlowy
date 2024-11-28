import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { FieldURLType, FileBlockData } from '@/application/types';
import FileDropzone from '@/components/_shared/file-dropzone/FileDropzone';
import { notify } from '@/components/_shared/notify';
import { TabPanel, ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import EmbedLink from 'src/components/_shared/image-upload/EmbedLink';

export const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
export function getFileName (url: string) {
  const urlObj = new URL(url);
  const name = urlObj.pathname.split('/').pop();

  return name;
}

function FileBlockPopoverContent ({
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

  const handleChangeUploadFile = useCallback(async (files: File[]) => {
    const file = files[0];

    if (!file) return;

    if (file.size > MAX_IMAGE_SIZE) {
      notify.error('File size is too large, please upload a file less than 10MB');

      return;
    }

    let url = URL.createObjectURL(file);

    try {
      if (uploadFile) {
        url = await uploadFile(file);
      }
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);

      return;
    }

    CustomEditor.setBlockData(editor, blockId, {
      url,
      name: file.name,
      uploaded_at: Date.now(),
      url_type: FieldURLType.Upload,
    } as FileBlockData);
    onClose();
  }, [editor, blockId, onClose, uploadFile]);

  const tabOptions = useMemo(() => {
    return [
      {
        key: 'upload',
        label: t('button.upload'),
        panel: <FileDropzone
          placeholder={<span>
            {t('document.plugins.file.fileUploadHint')}
            <span className={'text-fill-default'}>{t('document.plugins.photoGallery.browserLayout')}</span>
          </span>}
          onChange={handleChangeUploadFile}
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
  }, [entry, handleChangeUploadFile, handleInsertEmbedLink, t]);

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