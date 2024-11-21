import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { ImageBlockData, ImageType } from '@/application/types';
import { Unsplash } from '@/components/_shared/image-upload';
import EmbedLink from '@/components/_shared/image-upload/EmbedLink';
import UploadImage from '@/components/_shared/image-upload/UploadImage';
import { TabPanel, ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';

function ImageBlockPopoverContent ({
  blockId,
  onClose,
}: {
  blockId: string;
  onClose: () => void;
}) {

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

  const tabOptions = useMemo(() => {
    return [
      {
        key: 'upload',
        label: t('button.upload'),
        panel: <UploadImage
          onDone={(url) => {
            handleUpdateLink(url, ImageType.Internal);
          }}
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
        panel: <Unsplash onDone={handleUpdateLink} />,
      },
    ];
  }, [entry, handleUpdateLink, t]);

  const selectedIndex = tabOptions.findIndex((tab) => tab.key === tabValue);

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
      <div className={'pt-4'}>
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