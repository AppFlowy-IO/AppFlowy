import { useState } from 'react';
import { currentUserActions } from '../../../stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { useNavigate } from 'react-router-dom';

export const useLogin = () => {
  const [showPassword, setShowPassword] = useState(false);
  const appDispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const navigate = useNavigate();

  function onTogglePassword() {
    setShowPassword(!showPassword);
  }

  function onSignInClick() {
    appDispatch(
      currentUserActions.updateUser({
        ...currentUser,
        isAuthenticated: true,
      })
    );
    navigate('/');
  }

  return { showPassword, onTogglePassword, onSignInClick };
};
