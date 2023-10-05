import { t } from 'i18next';
import { Button, Input, IconButton } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ReactComponent as SearchSvg } from '$app/assets/search.svg';
import { ReactComponent as SettingsSvg } from '$app/assets/settings.svg';

export const GridToolbar = () => {
  // TODO: get view title
  const title = 'My plans on week';

  return (
    <div className="database-grid-toolbar flex items-center h-10 px-16">
      <div className="flex flex-1 items-center font-semibold">
        <span className="text-base">
          {title}
        </span>
        <span className="ml-2">
          <IconButton size="small">
            <SettingsSvg />
          </IconButton>
        </span>
      </div>
      <div className="flex items-center">
        <Button
          variant="text"
          color="inherit"
          size="small"
          startIcon={<AddSvg />}
        >
          {t('grid.createView')}
        </Button>
        <Input
          className="ml-8 w-36"
          placeholder={t('search.label')}
          disableUnderline
          startAdornment={<SearchSvg className="w-4 h-4 mr-2" />}
        />
      </div>
    </div>
  );
};