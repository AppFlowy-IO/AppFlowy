import { Alert } from '@mui/material';
import { FallbackProps } from 'react-error-boundary';

export function ElementFallbackRender({ error }: FallbackProps) {
  return (
    <Alert severity={'error'} variant={'standard'} className={'my-2'}>
      <p>Something went wrong:</p>
      <pre>{error.message}</pre>
    </Alert>
  );
}
