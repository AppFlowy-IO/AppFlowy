import React, { useCallback } from 'react';
import { SpaceView } from '@/application/types';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CheckIcon } from '@/assets/selected.svg';
import { renderColor } from '@/utils/color';
import SpaceIcon from '@/components/publish/header/SpaceIcon';
import { Button, CircularProgress, Tooltip } from '@mui/material';
import { ReactComponent as LockSvg } from '@/assets/lock.svg';

export interface SpaceListProps {
  value: string;
  onChange?: (value: string) => void;
  spaceList: SpaceView[];
  loading?: boolean;
}

function SpaceList({ loading, spaceList, value, onChange }: SpaceListProps) {
  const { t } = useTranslation();

  const getExtraObj = useCallback((extra: string) => {
    try {
      return extra
        ? (JSON.parse(extra) as {
            is_space?: boolean;
            space_icon?: string;
            space_icon_color?: string;
          })
        : {};
    } catch (e) {
      return {};
    }
  }, []);

  const renderSpace = useCallback(
    (space: SpaceView) => {
      const extraObj = getExtraObj(space.extra || '');

      return (
        <div className={'flex items-center gap-[10px] overflow-hidden text-sm'}>
          <span
            className={'icon h-5 w-5'}
            style={{
              backgroundColor: extraObj.space_icon_color ? renderColor(extraObj.space_icon_color) : undefined,
              borderRadius: '8px',
            }}
          >
            <SpaceIcon value={extraObj.space_icon || ''} />
          </span>
          <div className={'flex flex-1 items-center gap-2 truncate'}>
            {space.name}
            {space.isPrivate && <LockSvg className={'h-3.5 w-3.5 text-icon-primary'} />}
          </div>
        </div>
      );
    },
    [getExtraObj]
  );

  return (
    <div className={'flex max-h-[280px] w-[360px] flex-col gap-2 overflow-hidden max-sm:w-full'}>
      <div className={'text-sm text-text-caption'}>{t('publish.addTo')}</div>
      {loading ? (
        <div className={'flex w-full items-center justify-center'}>
          <CircularProgress size={24} />
        </div>
      ) : (
        <div className={'appflowy-scroller flex w-full flex-1 flex-col gap-1 overflow-y-auto overflow-x-hidden'}>
          {spaceList.map((space) => {
            const isSelected = value === space.id;

            return (
              <Tooltip title={space.name} key={space.id} placement={'bottom'} enterDelay={1000} enterNextDelay={1000}>
                <Button
                  variant={'text'}
                  color={'inherit'}
                  className={'flex items-center p-1 font-normal'}
                  onClick={() => {
                    onChange?.(space.id);
                  }}
                >
                  <div className={'flex-1 overflow-hidden text-left'}>{renderSpace(space)}</div>
                  <div className={'h-6 w-6'}>
                    {isSelected && <CheckIcon className={'h-6 w-6 text-content-blue-400'} />}
                  </div>
                </Button>
              </Tooltip>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default SpaceList;
