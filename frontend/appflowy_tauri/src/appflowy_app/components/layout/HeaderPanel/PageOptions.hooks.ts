import { useState } from 'react';
import { useAuth } from '../../auth/auth.hooks';

export const usePageOptions = () => {
  const [showOptionsPopup, setShowOptionsPopup] = useState(false);
  const { logout } = useAuth();

  const onOptionsClick = () => {
    setShowOptionsPopup(true);
  };

  const onClose = () => {
    setShowOptionsPopup(false);
  };

  const onSignOutClick = async () => {
    await logout();
    onClose();
  };

  return {
    showOptionsPopup,
    onOptionsClick,
    onClose,
    onSignOutClick,
  };
};
