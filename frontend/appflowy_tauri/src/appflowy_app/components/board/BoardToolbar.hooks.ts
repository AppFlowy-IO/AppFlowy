import { useState } from 'react';

export const useBoardToolbar = () => {
  const [showSettings, setShowSettings] = useState(false);
  const [showAllFields, setShowAllFields] = useState(false);
  const [showGroupFields, setShowGroupFields] = useState(false);

  const onSettingsClick = () => {
    setShowSettings(!showSettings);
  };

  const onFieldsClick = () => {
    setShowSettings(false);
    setShowAllFields(true);
  };

  const onGroupClick = () => {
    setShowSettings(false);
    setShowGroupFields(true);
  };

  const hidePopup = () => {
    setShowSettings(false);
    setShowAllFields(false);
    setShowGroupFields(false);
  };

  return {
    showSettings,
    onSettingsClick,
    onFieldsClick,
    onGroupClick,
    hidePopup,
    showAllFields,
    showGroupFields,
  };
};
