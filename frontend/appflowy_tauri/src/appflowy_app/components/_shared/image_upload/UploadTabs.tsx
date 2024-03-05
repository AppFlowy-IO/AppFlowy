import React, { SyntheticEvent, useCallback, useState } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { TabPanel, ViewTab, ViewTabs } from '$app/components/database/components/tab_bar/ViewTabs';
import SwipeableViews from 'react-swipeable-views';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';

export enum TAB_KEY {
  Colors = 'colors',
  UPLOAD = 'upload',
  EMBED_LINK = 'embed_link',
  UNSPLASH = 'unsplash',
}

export type TabOption = {
  key: TAB_KEY;
  label: string;
  Component: React.ComponentType<{
    onDone?: (value: string) => void;
    onEscape?: () => void;
  }>;
  onDone?: (value: string) => void;
};

export function UploadTabs({
  tabOptions,
  popoverProps,
  containerStyle,
  extra,
}: {
  containerStyle?: React.CSSProperties;
  tabOptions: TabOption[];
  popoverProps?: PopoverProps;
  extra?: React.ReactNode;
}) {
  const [tabValue, setTabValue] = useState<TAB_KEY>(() => {
    return tabOptions[0].key;
  });

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
        popoverProps?.onClose?.({}, 'escapeKeyDown');
      }

      if (e.key === 'Tab') {
        e.preventDefault();
        e.stopPropagation();
        setTabValue((prev) => {
          const currentIndex = tabOptions.findIndex((tab) => tab.key === prev);
          let nextIndex = currentIndex + 1;

          if (e.shiftKey) {
            nextIndex = currentIndex - 1;
          }

          return tabOptions[nextIndex % tabOptions.length]?.key ?? tabOptions[0].key;
        });
      }
    },
    [popoverProps, tabOptions]
  );

  return (
    <Popover
      {...popoverProps}
      {...PopoverCommonProps}
      open={popoverProps?.open ?? false}
      disableAutoFocus={false}
      onKeyDown={onKeyDown}
      PaperProps={{
        style: {
          padding: 0,
        },
      }}
    >
      <div style={containerStyle} className={'flex flex-col gap-4 overflow-hidden'}>
        <div className={'flex w-full items-center justify-between gap-2 border-b border-line-divider'}>
          <ViewTabs
            value={tabValue}
            onChange={handleTabChange}
            scrollButtons={false}
            variant='scrollable'
            allowScrollButtonsMobile
            className={'min-h-[38px] px-2'}
          >
            {tabOptions.map((tab) => {
              const { key, label } = tab;

              return <ViewTab key={key} iconPosition='start' color='inherit' label={label} value={key} />;
            })}
          </ViewTabs>
          {extra}
        </div>

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
                  <Component onDone={onDone} onEscape={() => popoverProps?.onClose?.({}, 'escapeKeyDown')} />
                </TabPanel>
              );
            })}
          </SwipeableViews>
        </div>
      </div>
    </Popover>
  );
}
