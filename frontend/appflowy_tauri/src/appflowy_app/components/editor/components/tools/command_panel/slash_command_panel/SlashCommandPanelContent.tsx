import React, { useCallback, useRef } from 'react';
import { MenuItem, MenuList, Typography } from '@mui/material';
import { useSlashCommandPanel } from '$app/components/editor/components/tools/command_panel/slash_command_panel/SlashCommandPanel.hooks';
import { useKeyDown } from '$app/components/editor/components/tools/command_panel/usePanel.hooks';

function SlashCommandPanelContent({
  closePanel,
  searchText,
}: {
  closePanel: (deleteText?: boolean) => void;
  searchText: string;
}) {
  const scrollRef = useRef<HTMLDivElement>(null);

  const { options, selectedType, setSelectedType } = useSlashCommandPanel({
    searchText,
    closePanel,
    open: true,
  });

  const handleSelectType = useCallback(
    (type?: string | number) => {
      if (type === undefined) return;

      setSelectedType(Number(type));
    },
    [setSelectedType]
  );

  useKeyDown({
    scrollRef,
    panelOpen: true,
    closePanel,
    options,
    selectedKey: selectedType,
    setSelectedKey: handleSelectType,
  });
  return (
    <div ref={scrollRef} className={'max-h-[360px] w-[220px] overflow-auto overflow-x-hidden py-1 pl-1'}>
      {options.length > 0 ? (
        options.map((group) => (
          <div key={group.key}>
            <Typography variant='body1' className={'p-2 text-text-caption'}>
              {group.label}
            </Typography>
            <MenuList className={'py-0 pl-1'}>
              {group.options.map((subOption) => {
                const Icon = subOption.Icon;

                return (
                  <MenuItem
                    onMouseEnter={() => setSelectedType(subOption.key)}
                    selected={selectedType === subOption.key}
                    data-type={subOption.key}
                    className={'ml-0 flex w-full items-center justify-start'}
                    key={subOption.key}
                    onClick={subOption.onClick}
                  >
                    <Icon className={'mr-2 h-4 w-4'} />
                    <div className={'flex-1'}>{subOption.label}</div>
                  </MenuItem>
                );
              })}
            </MenuList>
          </div>
        ))
      ) : (
        <Typography variant='body1' className={'p-3 text-text-caption'}>
          No results
        </Typography>
      )}
    </div>
  );
}

export default SlashCommandPanelContent;
