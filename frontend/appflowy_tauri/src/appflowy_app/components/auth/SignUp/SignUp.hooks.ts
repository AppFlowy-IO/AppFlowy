import { useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../../store';
import { currentUserActions } from '../../../redux/current-user/slice';
import { useNavigate } from 'react-router-dom';

export const useSignUp = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const appDispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const navigate = useNavigate();

  function onTogglePassword() {
    setShowPassword(!showPassword);
  }

  function onToggleConfirmPassword() {
    setShowConfirmPassword(!showConfirmPassword);
  }

  function onSignUpClick() {
    appDispatch(
      currentUserActions.updateUser({
        ...currentUser,
        isAuthenticated: true,
      })
    );
    navigate('/');
  }

  return { showPassword, onTogglePassword, showConfirmPassword, onToggleConfirmPassword, onSignUpClick };
};
