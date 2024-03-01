import React, { useCallback, useMemo, SyntheticEvent, useState } from 'react';
import Popover, { PopoverOrigin } from '@mui/material/Popover/Popover';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { TabPanel, ViewTab, ViewTabs } from '$app/components/database/components/tab_bar/ViewTabs';
import { useTranslation } from 'react-i18next';
import { EmbedLink, Unsplash } from '$app/components/_shared/image_upload';
import SwipeableViews from 'react-swipeable-views';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import { ImageNode, ImageType } from '$app/application/document/document.types';

enum TAB_KEY {
  UPLOAD = 'upload',
  EMBED_LINK = 'embed_link',
  UNSPLASH = 'unsplash',
}
const initialOrigin: {
  transformOrigin: PopoverOrigin;
  anchorOrigin: PopoverOrigin;
} = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'center',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
};

function UploadPopover({
  open,
  anchorEl,
  onClose,
  node,
}: {
  open: boolean;
  anchorEl: HTMLDivElement | null;
  onClose: () => void;
  node: ImageNode;
}) {
  const editor = useSlateStatic();

  const { t } = useTranslation();

  const { transformOrigin, anchorOrigin, isEntered, paperHeight, paperWidth } = usePopoverAutoPosition({
    initialPaperWidth: 433,
    initialPaperHeight: 300,
    anchorEl,
    initialAnchorOrigin: initialOrigin.anchorOrigin,
    initialTransformOrigin: initialOrigin.transformOrigin,
    open,
  });

  const tabOptions = useMemo(() => {
    return [
      // {
      //   label: t('button.upload'),
      //   key: TAB_KEY.UPLOAD,
      //   Component: UploadImage,
      // },
      {
        label: t('document.imageBlock.embedLink.label'),
        key: TAB_KEY.EMBED_LINK,
        Component: EmbedLink,
        onDone: (link: string) => {
          CustomEditor.setImageBlockData(editor, node, {
            url: link,
            image_type: ImageType.External,
          });
          onClose();
        },
      },
      {
        key: TAB_KEY.UNSPLASH,
        label: t('document.imageBlock.unsplash.label'),
        Component: Unsplash,
        onDone: (link: string) => {
          CustomEditor.setImageBlockData(editor, node, {
            url: link,
            image_type: ImageType.External,
          });
          onClose();
        },
      },
    ];
  }, [editor, node, onClose, t]);

  const [tabValue, setTabValue] = useState<TAB_KEY>(tabOptions[0].key);

  const handleTabChange = useCallback((_: SyntheticEvent, newValue: string) => {
    setTabValue(newValue as TAB_KEY);
  }, []);

  const selectedIndex = tabOptions.findIndex((tab) => tab.key === tabValue);

  const onKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      e.stopPropagation();

      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        onClose();
      }

      if (e.key === 'Tab') {
        e.preventDefault();
        e.stopPropagation();
        setTabValue((prev) => {
          const currentIndex = tabOptions.findIndex((tab) => tab.key === prev);
          const nextIndex = (currentIndex + 1) % tabOptions.length;

          return tabOptions[nextIndex]?.key ?? tabOptions[0].key;
        });
      }
    },
    [onClose, tabOptions]
  );

  return (
    <Popover
      {...PopoverCommonProps}
      disableAutoFocus={false}
      open={open && isEntered}
      anchorEl={anchorEl}
      transformOrigin={transformOrigin}
      anchorOrigin={anchorOrigin}
      onClose={onClose}
      onMouseDown={(e) => {
        e.stopPropagation();
      }}
      onKeyDown={onKeyDown}
      PaperProps={{
        style: {
          padding: 0,
        },
      }}
    >
      <div
        style={{
          maxWidth: paperWidth,
          maxHeight: paperHeight,
          overflow: 'hidden',
        }}
        className={'flex flex-col gap-4'}
      >
        <ViewTabs
          value={tabValue}
          onChange={handleTabChange}
          scrollButtons={false}
          variant='scrollable'
          allowScrollButtonsMobile
          className={'min-h-[38px] border-b border-line-divider px-2'}
        >
          {tabOptions.map((tab) => {
            const { key, label } = tab;

            return <ViewTab key={key} iconPosition='start' color='inherit' label={label} value={key} />;
          })}
        </ViewTabs>

        <div className={'h-full w-full flex-1 overflow-y-auto overflow-x-hidden'}>
          <SwipeableViews
            slideStyle={{
              overflow: 'hidden',
              height: '100%',
            }}
            axis={'x'}
            index={selectedIndex}
          >
            {tabOptions.map((tab, index) => {
              const { key, Component, onDone } = tab;

              return (
                <TabPanel className={'flex h-full w-full flex-col'} key={key} index={index} value={selectedIndex}>
                  <Component onDone={onDone} onEscape={onClose} />
                </TabPanel>
              );
            })}
          </SwipeableViews>
        </div>
      </div>
    </Popover>
  );
}

export default UploadPopover;
