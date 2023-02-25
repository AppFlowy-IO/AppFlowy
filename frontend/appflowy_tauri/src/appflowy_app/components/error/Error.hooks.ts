import { useAppDispatch, useAppSelector } from '../../stores/store';
import { errorActions } from '../../stores/reducers/error/slice';
import { useState } from 'react';

export const useError = () => {
  const dispatch = useAppDispatch();
  const error = useAppSelector((state) => state.error);
  const [errorMessage] = useState(error.message);
  const [displayError] = useState(error.display);

  const showError = (msg: string) => {
    dispatch(errorActions.showError(msg));
  };

  const hideError = () => {
    dispatch(errorActions.hideError());
  };

  return {
    showError,
    hideError,
    errorMessage,
    displayError,
  };
};
