import { ErrorBoundary } from 'react-error-boundary';
import { Log } from '$app/utils/log';
import { Alert } from '@mui/material';

export default function withErrorBoundary<T extends object>(WrappedComponent: React.ComponentType<T>) {
  return (props: T) => (
    <ErrorBoundary
      onError={(e) => {
        Log.error(e);
      }}
      fallback={<Alert color={'error'}>Something went wrong</Alert>}
    >
      <WrappedComponent {...props} />
    </ErrorBoundary>
  );
}
