import React, { useCallback, useRef } from 'react';
import { useMentionPanel } from '$app/components/editor/components/tools/command_panel/mention_panel/MentionPanel.hooks';
import { useKeyDown } from '$app/components/editor/components/tools/command_panel/usePanel.hooks';
import { useTranslation } from 'react-i18next';
import { MenuItem, MenuList, Typography } from '@mui/material';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';

function MentionPanelContent({
  closePanel,
  searchText,
}: {
  closePanel: (deleteText?: boolean) => void;
  searchText: string;
}) {
  const { t } = useTranslation();
  const scrollRef = useRef<HTMLDivElement>(null);

  const { options, selectedOptionId, setSelectedOptionId } = useMentionPanel({
    closePanel,
    searchText,
  });

  const handleSelectKey = useCallback(
    (key?: string | number) => {
      setSelectedOptionId(String(key));
    },
    [setSelectedOptionId]
  );

  useKeyDown({
    scrollRef,
    panelOpen: true,
    closePanel,
    options,
    selectedKey: selectedOptionId,
    setSelectedKey: handleSelectKey,
  });
  return (
    <div ref={scrollRef} className={'max-h-[360px] w-[300px] overflow-auto overflow-x-hidden'}>
      {options.length === 0 ? (
        <Typography variant='body1' className={'p-3 text-text-caption'}>
          No results
        </Typography>
      ) : (
        options.map((option, index) => (
          <div key={option.key} className={`${index !== 0 ? 'border-t border-line-divider' : ''}`}>
            <Typography variant='body1' className={'p-3 px-4 text-text-caption'}>
              {option.label}
            </Typography>
            <MenuList className={'px-2 pb-3 pt-0'}>
              {option.options.map((subOption) => {
                return (
                  <MenuItem
                    onMouseEnter={() => setSelectedOptionId(subOption.key)}
                    selected={selectedOptionId === subOption.key}
                    data-type={subOption.key}
                    className={'ml-0 flex w-full items-center justify-start px-2 py-1'}
                    key={subOption.key}
                    onClick={subOption.onClick}
                  >
                    <div className={'h-4 w-4'}>{subOption.icon?.value || <DocumentSvg />}</div>

                    <Typography variant='body1' className={'ml-2 text-xs'}>
                      {subOption.label || t('document.title.placeholder')}
                    </Typography>
                  </MenuItem>
                );
              })}
            </MenuList>
          </div>
        ))
      )}
    </div>
  );
}

export default MentionPanelContent;
