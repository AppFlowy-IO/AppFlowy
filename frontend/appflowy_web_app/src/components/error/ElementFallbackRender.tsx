import { Alert } from '@mui/material';
import { FallbackProps } from 'react-error-boundary';

export function ElementFallbackRender({ error, description }: FallbackProps & {
  description?: string;
}) {
  return (
    <Alert
      severity={'error'}
      variant={'standard'}
      contentEditable={false}
      className={'my-2'}
    >
      <p>Something went wrong:</p>
      <pre>{error.message}</pre>
      {description && <pre>{description}</pre>}
    </Alert>
  );
}
