import React, { useState } from 'react';
import { Menu, MenuItem, MenuProps, Popover } from '@mui/material';
import { useTranslation } from 'react-i18next';
import Properties from '$app/components/database/components/database_settings/Properties';
import { Field } from '$app/components/database/application';
import { FieldVisibility } from '@/services/backend';
import { updateFieldSetting } from '$app/components/database/application/field/field_service';
import { useViewId } from '$app/hooks';

type SettingsMenuProps = MenuProps;

function SettingsMenu(props: SettingsMenuProps) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [propertiesAnchorElPosition, setPropertiesAnchorElPosition] = useState<
    | undefined
    | {
        top: number;
        left: number;
      }
  >(undefined);

  const openProperties = Boolean(propertiesAnchorElPosition);

  const togglePropertyVisibility = async (field: Field) => {
    let visibility = field.visibility;

    if (visibility === FieldVisibility.AlwaysHidden) {
      visibility = FieldVisibility.AlwaysShown;
    } else {
      visibility = FieldVisibility.AlwaysHidden;
    }

    await updateFieldSetting(viewId, field.id, {
      visibility,
    });
  };

  return (
    <>
      <Menu {...props} disableRestoreFocus={true}>
        <MenuItem
          onClick={(event) => {
            const rect = event.currentTarget.getBoundingClientRect();

            setPropertiesAnchorElPosition({
              top: rect.top,
              left: rect.left + rect.width,
            });
            props.onClose?.({}, 'backdropClick');
          }}
        >
          {t('grid.settings.properties')}
        </MenuItem>
      </Menu>
      <Popover
        disableRestoreFocus={true}
        open={openProperties}
        onClose={() => {
          setPropertiesAnchorElPosition(undefined);
        }}
        anchorReference={'anchorPosition'}
        anchorPosition={propertiesAnchorElPosition}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
      >
        <Properties onItemClick={togglePropertyVisibility} />
      </Popover>
    </>
  );
}

export default SettingsMenu;
