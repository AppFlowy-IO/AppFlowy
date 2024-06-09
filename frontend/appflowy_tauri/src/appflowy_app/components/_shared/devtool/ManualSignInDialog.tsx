import React from 'react';
import { CircularProgress, DialogActions, DialogProps, Tab, Tabs, TextareaAutosize } from '@mui/material';
import Dialog from '@mui/material/Dialog';
import DialogContent from '@mui/material/DialogContent';
import Button from '@mui/material/Button';
import { useAuth } from '$app/components/auth/auth.hooks';
import TextField from '@mui/material/TextField';

function ManualSignInDialog(props: DialogProps) {
  const [uri, setUri] = React.useState('');
  const [loading, setLoading] = React.useState(false);
  const { signInWithOAuth, signInWithEmailPassword } = useAuth();
  const [tab, setTab] = React.useState(0);
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [domain, setDomain] = React.useState('');
  const handleSignIn = async () => {
    setLoading(true);
    try {
      if (tab === 1) {
        if (!email || !password) return;
        await signInWithEmailPassword(email, password, domain);
      } else {
        await signInWithOAuth(uri);
      }
    } finally {
      setLoading(false);
    }

    props?.onClose?.({}, 'backdropClick');
  };

  return (
    <Dialog
      {...props}
      sx={{
        zIndex: 1500,
      }}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          void handleSignIn();
        }
      }}
    >
      <DialogContent className={'pt-3'}>
        <Tabs
          className={'mb-4'}
          defaultValue={0}
          value={tab}
          onChange={(_, value) => {
            setTab(value);
          }}
        >
          <Tab value={0} label={'OAuth URI'} />
          <Tab value={1} label={'Email & Password'} />
        </Tabs>
        {tab === 1 ? (
          <div className={'flex flex-col gap-3'}>
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
            <TextField
              size={'small'}
              label={'Domain(Optional)'}
              placeholder={'test.appflowy.cloud'}
              onChange={(e) => setDomain(e.target.value)}
            />
          </div>
        ) : (
          <TextareaAutosize
            value={uri}
            autoFocus
            className={'max-h-[300px] w-[400px] overflow-hidden rounded-md border border-line-border p-2 text-xs'}
            placeholder={'Paste the OAuth URI here'}
            minRows={3}
            spellCheck={false}
            onChange={(e) => {
              setUri(e.target.value);
            }}
          />
        )}
      </DialogContent>
      <DialogActions className={'mb-4 w-full px-6'}>
        <Button
          size={'small'}
          variant={'outlined'}
          color={'inherit'}
          onClick={() => props?.onClose?.({}, 'backdropClick')}
        >
          Cancel
        </Button>
        <Button disabled={loading} size={'small'} className={'w-auto'} variant={'outlined'} onClick={handleSignIn}>
          {loading ? <CircularProgress size={14} /> : 'Sign In'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default ManualSignInDialog;
