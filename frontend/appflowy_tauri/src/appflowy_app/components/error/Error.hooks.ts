import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { errorActions } from '$app_reducers/error/slice';
import { useCallback, useEffect, useState } from 'react';

export const useError = (e: Error) => {
  const dispatch = useAppDispatch();
  const error = useAppSelector((state) => state.error);
  const [errorMessage, setErrorMessage] = useState('');
  const [displayError, setDisplayError] = useState(false);

  useEffect(() => {
    setDisplayError(error.display);
    setErrorMessage(error.message);
  }, [error]);

  const showError = useCallback(
    (msg: string) => {
      dispatch(errorActions.showError(msg));
    },
    [dispatch]
  );

  useEffect(() => {
    if (e) {
      showError(e.message);
    }
  }, [e, showError]);

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
