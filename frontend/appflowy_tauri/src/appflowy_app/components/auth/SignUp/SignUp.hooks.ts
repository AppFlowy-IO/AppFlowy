import { useState } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth.hooks';

export const useSignUp = () => {
  const [email, _setEmail] = useState('');
  const [displayName, _setDisplayName] = useState('');
  const [password, _setPassword] = useState('');
  const [repeatedPassword, _setRepeatedPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const appDispatch = useAppDispatch();
  const navigate = useNavigate();
  const { register } = useAuth();
  const [authError, setAuthError] = useState(false);

  const setEmail = (v: string) => {
    setAuthError(false);
    _setEmail(v);
  };

  const setDisplayName = (v: string) => {
    setAuthError(false);
    _setDisplayName(v);
  };

  const setPassword = (v: string) => {
    setAuthError(false);
    _setPassword(v);
  };

  const setRepeatedPassword = (v: string) => {
    setAuthError(false);
    _setRepeatedPassword(v);
  };

  function onTogglePassword() {
    setShowPassword(!showPassword);
  }

  function onToggleConfirmPassword() {
    setShowConfirmPassword(!showConfirmPassword);
  }

  async function onSignUpClick() {
    try {
      const result = await register(email, password, displayName);
      const { id, token } = result;

      appDispatch(
        currentUserActions.updateUser({
          id,
          token,
          email,
          displayName,
          isAuthenticated: true,
        })
      );
      navigate('/');
    } catch (e) {
      setAuthError(true);
    }
  }

  return {
    email,
    setEmail,
    displayName,
    setDisplayName,
    password,
    setPassword,
    repeatedPassword,
    setRepeatedPassword,
    showPassword,
    onTogglePassword,
    showConfirmPassword,
    onToggleConfirmPassword,
    onSignUpClick,
    authError,
  };
};
