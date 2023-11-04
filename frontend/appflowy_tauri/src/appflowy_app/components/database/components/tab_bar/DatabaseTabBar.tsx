import { FC, MouseEventHandler, useCallback, useEffect, useState } from 'react';
import { IconButton, Stack } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ViewTabs, ViewTab } from './ViewTabs';
import { TextButton } from './TextButton';
import { SortMenu } from '../sort';
import { useAppSelector } from '$app/stores/store';
import { useTranslation } from 'react-i18next';
import { Simulate } from 'react-dom/test-utils';

export interface DatabaseTabBarProps {
  childViewIds: string[];
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

export const DatabaseTabBar: FC<DatabaseTabBarProps> = ({ childViewIds, selectedViewId, setSelectedViewId }) => {
  const { t } = useTranslation();
  const views = useAppSelector((state) => {
    const map = state.pages.pageMap;

    return childViewIds.map((id) => map[id]).filter(Boolean);
  });
  const [sortAnchorEl, setSortAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(sortAnchorEl);

  const handleChange = (_: React.SyntheticEvent, newValue: string) => {
    setSelectedViewId?.(newValue);
  };

  const handleClick = useCallback<MouseEventHandler<HTMLElement>>((event) => {
    setSortAnchorEl(event.currentTarget);
  }, []);

  const handleClose = () => {
    setSortAnchorEl(null);
  };

  useEffect(() => {
    if (selectedViewId === undefined && views.length > 0) {
      setSelectedViewId?.(views[0].id);
    }
  }, [selectedViewId, setSelectedViewId, views]);

  return (
    <div className='-mb-px flex items-center'>
      <div className='flex flex-1 items-center'>
        <ViewTabs value={selectedViewId} onChange={handleChange}>
          {views.map((view) => (
            <ViewTab
              key={view.id}
              icon={undefined}
              iconPosition='start'
              color='inherit'
              label={view.name || t('grid.title.placeholder')}
              value={view.id}
            />
          ))}
        </ViewTabs>
        <IconButton size='small'>
          <AddSvg />
        </IconButton>
      </div>
      <Stack className='text-neutral-500' direction='row' spacing='2px'>
        <TextButton color='inherit'>{t('grid.settings.filter')}</TextButton>
        <TextButton color='inherit' onClick={handleClick}>
          {t('grid.settings.sort')}
        </TextButton>
        <SortMenu open={open} anchorEl={sortAnchorEl} onClose={handleClose} />
      </Stack>
    </div>
  );
};
