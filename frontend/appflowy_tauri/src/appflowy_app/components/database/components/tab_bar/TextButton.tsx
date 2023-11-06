import { Button, ButtonProps, styled } from '@mui/material';

export const TextButton = styled(Button)<ButtonProps>(() => ({
  padding: '2px 6px',
  fontSize: '0.75rem',
  lineHeight: '1rem',
  fontWeight: 400,
  minWidth: 'unset',
}));
