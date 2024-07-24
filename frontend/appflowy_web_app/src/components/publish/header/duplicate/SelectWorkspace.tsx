import React, { useCallback, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Divider, IconButton, Tooltip } from '@mui/material';
import { Workspace } from '@/application/types';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';
import { ReactComponent as CheckIcon } from '@/assets/selected.svg';
import { Popover } from '@/components/_shared/popover';

export interface SelectWorkspaceProps {
  value: string;
  onChange?: (value: string) => void;
  workspaceList: Workspace[];
}

function SelectWorkspace({ value, onChange, workspaceList }: SelectWorkspaceProps) {
  const { t } = useTranslation();
  const email = 'lu@appflowy.io';
  const selectedWorkspace = useMemo(() => {
    return workspaceList.find((workspace) => workspace.id === value);
  }, [value, workspaceList]);
  const ref = useRef<HTMLButtonElement | null>(null);
  const [selectOpen, setSelectOpen] = useState<boolean>(false);

  const renderWorkspace = useCallback(
    (workspace: Workspace) => {
      return (
        <div className={'flex items-center gap-[10px] overflow-hidden'}>
          <div className={'h-8 w-8 text-2xl'}>{workspace.icon}</div>
          <div className={'flex flex-1 flex-col items-start gap-0.5 overflow-hidden'}>
            <div className={'w-full truncate text-left text-sm font-medium'}>{workspace.name}</div>
            <div className={'text-xs text-text-caption'}>
              {t('publish.membersCount', {
                count: workspace.memberCount || 0,
              })}
            </div>
          </div>
        </div>
      );
    },
    [t]
  );

  return (
    <div className={'flex w-[360px] flex-col gap-2 max-sm:w-full'}>
      <div className={'text-sm text-text-caption'}>{t('publish.selectWorkspace')}</div>
      <Button
        ref={ref}
        onClick={() => {
          setSelectOpen(true);
        }}
        className={'px-3 py-2'}
        variant={'outlined'}
        color={'inherit'}
      >
        <div className={'flex w-full items-center gap-[10px]'}>
          <div className={'flex-1 overflow-hidden'}>{selectedWorkspace ? renderWorkspace(selectedWorkspace) : null}</div>
          <IconButton size={'small'} className={`h-6 w-6 ${selectOpen ? '-rotate-90' : 'rotate-90'} transform`}>
            <RightIcon className={'h-6 w-6'} />
          </IconButton>
        </div>
      </Button>
      <Popover
        anchorEl={ref.current}
        open={selectOpen}
        transformOrigin={{
          vertical: -8,
          horizontal: 'left',
        }}
        onClose={() => {
          setSelectOpen(false);
        }}
      >
        <div className={'flex max-h-[360px] w-[360px] flex-col gap-1 p-2 max-sm:w-full'}>
          <div className={'w-full px-3 py-2 text-sm font-medium text-text-caption'}>{email}</div>
          <Divider />
          <div className={'appflowy-scroller flex flex-1 flex-col overflow-y-auto overflow-x-hidden'}>
            {workspaceList.map((workspace) => {
              const isSelected = workspace.id === selectedWorkspace?.id;

              return (
                <Tooltip
                  title={workspace.name}
                  key={workspace.id}
                  placement={'bottom'}
                  enterDelay={1000}
                  enterNextDelay={1000}
                >
                  <Button
                    onClick={() => {
                      onChange?.(workspace.id);
                      setSelectOpen(false);
                    }}
                    className={'w-full px-3 py-2'}
                    variant={'text'}
                    color={'inherit'}
                  >
                    <div className={'flex-1 overflow-hidden'}>{renderWorkspace(workspace)}</div>
                    <div className={'h-6 w-6'}>
                      {isSelected && <CheckIcon className={'h-6 w-6 text-content-blue-400'} />}
                    </div>
                  </Button>
                </Tooltip>
              );
            })}
          </div>
        </div>
      </Popover>
    </div>
  );
}

export default SelectWorkspace;
