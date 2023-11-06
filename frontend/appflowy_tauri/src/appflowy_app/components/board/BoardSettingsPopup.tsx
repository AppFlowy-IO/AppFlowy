import { useEffect, useState } from 'react';
import { PropertiesSvg } from '$app/components/_shared/svg/PropertiesSvg';
import { IPopupItem, PopupSelect } from '$app/components/_shared/PopupSelect';
import { useTranslation } from 'react-i18next';
import { GroupByFieldSvg } from '$app/components/_shared/svg/GroupByFieldSvg';

export const BoardSettingsPopup = ({
  hidePopup,
  onFieldsClick,
  onGroupClick,
}: {
  hidePopup: () => void;
  onFieldsClick: () => void;
  onGroupClick: () => void;
}) => {
  const [settingsItems, setSettingsItems] = useState<IPopupItem[]>([]);
  const { t } = useTranslation();

  useEffect(() => {
    setSettingsItems([
      {
        icon: (
          <i className={'h-5 w-5'}>
            <PropertiesSvg></PropertiesSvg>
          </i>
        ),
        title: t('grid.settings.properties'),
        onClick: onFieldsClick,
      },
      {
        icon: (
          <i className={'h-5 w-5'}>
            <GroupByFieldSvg></GroupByFieldSvg>
          </i>
        ),
        title: t('grid.settings.group'),
        onClick: onGroupClick,
      },
    ]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [t]);

  return (
    <PopupSelect
      onOutsideClick={() => hidePopup()}
      items={settingsItems}
      className={'absolute left-full top-full z-10 text-xs'}
    ></PopupSelect>
  );
};
