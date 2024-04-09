import { useError } from './Error.hooks';
import { ErrorModal } from './ErrorModal';

export const ErrorHandlerPage = ({ error }: { error: Error }) => {
  const { hideError, errorMessage, displayError } = useError(error);

  return displayError ? <ErrorModal message={errorMessage} onClose={hideError}></ErrorModal> : <></>;
};
