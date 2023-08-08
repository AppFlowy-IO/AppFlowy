import { Button, Input, Icon, IconButton } from '@mui/material';
import AddSvg from '$app/components/_shared/svg/AddSvg';
import { SearchSvg } from '$app/components/_shared/svg/SearchSvg';
import { SettingsSvg } from '$app/components/_shared/svg/SettingsSvg';

export const GridToolbar = () => {
  return (
    <div className="database-grid-toolbar flex items-center h-10 px-16">
      <div className="flex flex-1 items-center font-semibold">
        <span className="text-base">
          My plans on week
        </span>
        <span className="ml-2">
          <IconButton className="h-5 w-5">
            <SettingsSvg />
          </IconButton>
        </span>
      </div>
      <div className="flex items-center">
        <Button
          variant="text"
          color="inherit"
          startIcon={(
            <Icon>
              <AddSvg />
            </Icon>
          )}
        >
          Add View
        </Button>
        <Input
          className="ml-8 w-36"
          placeholder="Search"
          disableUnderline
          startAdornment={(
            <Icon className="mr-2" fontSize="small">
              <SearchSvg />
            </Icon>
          )}
        />
      </div>
    </div>
  );
};