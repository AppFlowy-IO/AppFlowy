import { useState } from 'react';
import { currentUserActions } from '../../../redux/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../../store';
import { useNavigate } from 'react-router-dom';

export const useConfirmAccount = () => {
  const [otpValues, setOtpValues] = useState('');
  const appDispatch = useAppDispatch();
  const currentUser = useAppSelector((state) => state.currentUser);
  const navigate = useNavigate();

  const handleChange = (value: string) => {
    console.log({ value });
    setOtpValues(value);
  };

  const onConfirmClick = () => {
    appDispatch(
      currentUserActions.updateUser({
        ...currentUser,
        isAuthenticated: true,
      })
    );
    navigate('/');
  };

  return {
    otpValues,
    handleChange,
    onConfirmClick,
  };
};
