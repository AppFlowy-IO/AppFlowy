import { Alert } from '@mui/material';
import { FallbackProps } from 'react-error-boundary';

export function ErrorBoundaryFallbackComponent({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <Alert severity='error' className='mb-2'>
      <p>Something went wrong:</p>
      <pre>{error.message}</pre>
      <button onClick={resetErrorBoundary}>Try again</button>
    </Alert>
  );
}
