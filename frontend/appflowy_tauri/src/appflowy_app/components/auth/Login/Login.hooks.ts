import { useState } from 'react';
import { currentUserActions } from '../../../stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth.hooks';

export const useLogin = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const appDispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const navigate = useNavigate();
  const { login } = useAuth();
  const [authError, setAuthError] = useState(false);

  function onTogglePassword() {
    setShowPassword(!showPassword);
  }

  // reset error
  function _setEmail(v: string) {
    setAuthError(false);
    setEmail(v);
  }

  function _setPassword(v: string) {
    setAuthError(false);
    setPassword(v);
  }

  async function onSignInClick() {
    try {
      const result = await login(email, password);
      const { id, name, token } = result;
      appDispatch(
        currentUserActions.updateUser({
          id: id,
          displayName: name,
          email: email,
          token: token,
          isAuthenticated: true,
        })
      );
      navigate('/');
    } catch (e) {
      setAuthError(true);
    }
  }

  return {
    showPassword,
    onTogglePassword,
    onSignInClick,
    email,
    setEmail: _setEmail,
    password,
    setPassword: _setPassword,
    authError,
  };
};
