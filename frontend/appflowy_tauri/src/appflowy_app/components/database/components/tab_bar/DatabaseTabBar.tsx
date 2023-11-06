import { FC, MouseEventHandler, useCallback, useState } from 'react';
import { t } from 'i18next';
import { IconButton, Stack } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { DatabaseView } from '../../application';
import { useSelectDatabaseView } from '../../Database.hooks';
import { ViewTabs, ViewTab } from './ViewTabs';
import { TextButton } from './TextButton';
import { SortMenu } from '../sort';

export interface DatabaseTabBarProps {
  views: DatabaseView[];
}

export const DatabaseTabBar: FC<DatabaseTabBarProps> = ({
  views,
}) => {
  const [selectedViewId, selectViewId] = useSelectDatabaseView();
  const [sortAnchorEl, setSortAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(sortAnchorEl);

  const handleChange = (event: React.SyntheticEvent, newValue: string) => {
    selectViewId(newValue);
  };

  const handleClick = useCallback<MouseEventHandler<HTMLElement>>((event) => {
    setSortAnchorEl(event.currentTarget);
  }, []);

  const handleClose = () => {
    setSortAnchorEl(null);
  };

  return (
    <div className="flex items-center -mb-px">
      <div className='flex flex-1 items-center'>
        <ViewTabs value={selectedViewId} onChange={handleChange}>
          {views.map(view => (
            <ViewTab
              key={view.id}
              icon={undefined}
              iconPosition="start"
              color="inherit"
              label={view.name}
              value={view.id}
            />
          ))}
        </ViewTabs>
        <IconButton size="small">
          <AddSvg />
        </IconButton>
      </div>
      <Stack className="text-neutral-500" direction="row" spacing="2px">
        <TextButton color="inherit">
          {t('grid.settings.filter')}
        </TextButton>
        <TextButton color="inherit" onClick={handleClick}>
          {t('grid.settings.sort')}
        </TextButton>
        <SortMenu open={open} anchorEl={sortAnchorEl} onClose={handleClose} />
      </Stack>
    </div>
  );
};
