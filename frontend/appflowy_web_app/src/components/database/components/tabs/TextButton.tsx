import { Button, ButtonProps, styled } from '@mui/material';

export const TextButton = styled((props: ButtonProps) => (
  <Button
    {...props}
    sx={{
      '&.MuiButton-colorInherit': {
        color: 'var(--text-caption)',
      },
    }}
  />
))<ButtonProps>(() => ({
  padding: '4px 6px',
  fontSize: '0.75rem',
  lineHeight: '1rem',
  fontWeight: 400,
  minWidth: 'unset',
}));
