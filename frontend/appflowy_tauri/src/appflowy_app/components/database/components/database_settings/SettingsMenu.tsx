import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Menu, MenuProps, Popover } from '@mui/material';
import { useTranslation } from 'react-i18next';
import Properties from '$app/components/database/components/database_settings/Properties';
import { Field } from '$app/application/database';
import { FieldVisibility } from '@/services/backend';
import { updateFieldSetting } from '$app/application/database/field/field_service';
import { useViewId } from '$app/hooks';
import KeyboardNavigation from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

type SettingsMenuProps = MenuProps;

function SettingsMenu(props: SettingsMenuProps) {
  const viewId = useViewId();
  const ref = useRef<HTMLDivElement>(null);
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

  const options = useMemo(() => {
    return [{ key: 'properties', content: <div data-key={'properties'}>{t('grid.settings.properties')}</div> }];
  }, [t]);

  const onConfirm = useCallback(
    (optionKey: string) => {
      if (optionKey === 'properties') {
        const target = ref.current?.querySelector(`[data-key=${optionKey}]`) as HTMLElement;
        const rect = target.getBoundingClientRect();

        setPropertiesAnchorElPosition({
          top: rect.top,
          left: rect.left + rect.width,
        });
        props.onClose?.({}, 'backdropClick');
      }
    },
    [props]
  );

  return (
    <>
      <Menu {...props} ref={ref} disableRestoreFocus={true}>
        <KeyboardNavigation
          onConfirm={onConfirm}
          onEscape={() => {
            props.onClose?.({}, 'escapeKeyDown');
          }}
          options={options}
        />
      </Menu>
      <Popover
        keepMounted={false}
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
        onKeyDown={(e) => {
          if (e.key === 'Escape') {
            e.preventDefault();
            e.stopPropagation();
            props.onClose?.({}, 'escapeKeyDown');
          }
        }}
      >
        <Properties onItemClick={togglePropertyVisibility} />
      </Popover>
    </>
  );
}

export default SettingsMenu;
