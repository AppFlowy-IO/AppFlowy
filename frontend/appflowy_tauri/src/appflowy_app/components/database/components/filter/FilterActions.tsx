import React, { useMemo, useState } from 'react';
import { IconButton, Menu } from '@mui/material';
import { ReactComponent as MoreSvg } from '$app/assets/details.svg';
import { Filter } from '$app/application/database';
import { useTranslation } from 'react-i18next';
import { deleteFilter } from '$app/application/database/filter/filter_service';
import { useViewId } from '$app/hooks';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

function FilterActions({ filter }: { filter: Filter }) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [disableSelect, setDisableSelect] = useState(true);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const onClose = () => {
    setDisableSelect(true);
    setAnchorEl(null);
  };

  const onDelete = async () => {
    try {
      await deleteFilter(viewId, filter);
    } catch (e) {
      // toast.error(e.message);
    }

    setDisableSelect(true);
  };

  const options: KeyboardNavigationOption[] = useMemo(
    () => [
      {
        key: 'delete',
        content: t('grid.settings.deleteFilter'),
      },
    ],
    [t]
  );

  return (
    <>
      <IconButton
        onClick={(e) => {
          setAnchorEl(e.currentTarget);
        }}
        className={'mx-2 my-1.5'}
      >
        <MoreSvg />
      </IconButton>
      {open && (
        <Menu
          onKeyDown={(e) => {
            if (e.key === 'Escape') {
              e.preventDefault();
              e.stopPropagation();
              onClose();
            }
          }}
          keepMounted={false}
          open={open}
          anchorEl={anchorEl}
          onClose={onClose}
        >
          <KeyboardNavigation
            onKeyDown={(e) => {
              if (e.key === 'ArrowDown') {
                setDisableSelect(false);
              }
            }}
            disableSelect={disableSelect}
            options={options}
            onConfirm={onDelete}
            onEscape={onClose}
          />
        </Menu>
      )}
    </>
  );
}

export default FilterActions;
