import { useAppDispatch, useAppSelector } from '../../stores/store';
import { errorActions } from '../../stores/reducers/error/slice';
import { useEffect, useState } from 'react';

export const useError = (e: Error) => {
  const dispatch = useAppDispatch();
  const error = useAppSelector((state) => state.error);
  const [errorMessage, setErrorMessage] = useState('');
  const [displayError, setDisplayError] = useState(false);

  useEffect(() => {
    setDisplayError(error.display);
    setErrorMessage(error.message);
  }, [error]);

  useEffect(() => {
    if (e) {
      showError(e.message);
    }
  }, [e]);

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
