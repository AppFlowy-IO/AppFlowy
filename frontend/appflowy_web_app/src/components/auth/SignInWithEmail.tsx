import { Button, CircularProgress, Dialog, DialogActions, DialogContent, TextField } from '@mui/material';
import React, { useState } from 'react';
import { useAuth } from '@/components/auth/auth.hooks';
import { useTranslation } from 'react-i18next';

function SignInWithEmail({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { signInWithEmailPassword } = useAuth();
  const handleSignIn = async () => {
    setLoading(true);
    try {
      await signInWithEmailPassword(email, password);
    } catch (e) {
      // Handle error
    }

    setLoading(false);
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      sx={{
        zIndex: 1500,
      }}
      PaperProps={{
        className: 'w-[400px]',
      }}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          void handleSignIn();
        }
      }}
    >
      <DialogContent className={'mt-2 flex w-full flex-col gap-3'}>
        <TextField
          label={'Email'}
          size={'small'}
          required={true}
          placeholder={'name@gmail.com'}
          type={'email'}
          onChange={(e) => setEmail(e.target.value)}
        />
        <TextField
          size={'small'}
          required={true}
          label={'Password'}
          placeholder={'Password'}
          type={'password'}
          onChange={(e) => setPassword(e.target.value)}
        />
      </DialogContent>
      <DialogActions className={'mb-4 flex w-full gap-2 px-6'}>
        <Button variant={'outlined'} className={'flex-1'} color={'inherit'} onClick={onClose}>
          {t('button.cancel')}
        </Button>
        <Button disabled={loading} className={'flex-1'} variant={'contained'} onClick={handleSignIn}>
          {loading ? <CircularProgress size={12} /> : t('button.signIn')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default SignInWithEmail;
