import { Button, Input, IconButton } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { ReactComponent as SearchSvg } from '$app/assets/search.svg';
import { ReactComponent as SettingsSvg } from '$app/assets/settings.svg';

export const GridToolbar = () => {
  return (
    <div className="database-grid-toolbar flex items-center h-10 px-16">
      <div className="flex flex-1 items-center font-semibold">
        <span className="text-base">
          My plans on week
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
          Add View
        </Button>
        <Input
          className="ml-8 w-36"
          placeholder="Search"
          disableUnderline
          startAdornment={<span className="mr-2"><SearchSvg className="w-4 h-4" /></span>}
        />
      </div>
    </div>
  );
};