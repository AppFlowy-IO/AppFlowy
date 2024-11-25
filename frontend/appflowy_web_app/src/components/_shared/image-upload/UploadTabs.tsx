import { Popover } from '@/components/_shared/popover';
import { TabPanel, ViewTab, ViewTabs } from '@/components/_shared/tabs/ViewTabs';
import React, { SyntheticEvent, useCallback, useEffect, useRef, useState } from 'react';
import { PopoverProps } from '@mui/material/Popover';
import SwipeableViews from 'react-swipeable-views';

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

export function UploadTabs ({
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
    [popoverProps, tabOptions],
  );

  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    const handleResize = () => {
      const top = el.getBoundingClientRect().top;
      const height = window.innerHeight - top - 20;

      el.style.maxHeight = `${height}px`;
    };

    if (tabValue === 'unsplash') {
      handleResize();
    }

  }, [tabValue]);

  return (
    <Popover
      {...popoverProps}
      open={popoverProps?.open ?? false}
      disableAutoFocus={false}
      onKeyDown={onKeyDown}
    >
      <div
        style={containerStyle}
        className={'flex flex-col min-w-[600px] gap-4 overflow-hidden'}
      >
        <div className={'flex w-full pt-1 items-center justify-center gap-2 border-b border-line-divider'}>
          <ViewTabs
            value={tabValue}
            onChange={handleTabChange}
            scrollButtons={false}
            variant="scrollable"
            allowScrollButtonsMobile
            className={'min-h-[38px] px-2'}
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
          {extra}
        </div>

        <div
          ref={ref}
          className={'h-full w-full appflowy-scroller flex-1 overflow-y-auto overflow-x-hidden'}
        >
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
                <TabPanel
                  className={'flex h-full w-full flex-col'}
                  key={key}
                  index={index}
                  value={selectedIndex}
                >
                  <Component
                    onDone={onDone}
                    onEscape={() => popoverProps?.onClose?.({}, 'escapeKeyDown')}
                  />
                </TabPanel>
              );
            })}
          </SwipeableViews>
        </div>
      </div>
    </Popover>
  );
}
