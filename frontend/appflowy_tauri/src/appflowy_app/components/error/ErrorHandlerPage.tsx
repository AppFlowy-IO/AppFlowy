import { useError } from './Error.hooks';
import { ErrorModal } from './ErrorModal';

export const ErrorHandlerPage = () => {
  const { hideError, errorMessage, displayError } = useError();

  return displayError ? <ErrorModal message={errorMessage} onClose={hideError}></ErrorModal> : <></>;
};
