import React, { useContext } from 'react';
import { Button } from '@mui/material';
import { useAuth } from '@/components/auth/auth.hooks';
import { AFConfigContext } from '@/AppConfig';

function Layout({ children }: { children: React.ReactNode }) {
  const { logout } = useAuth();
  const AFConfig = useContext(AFConfigContext);

  return (
    <div>
      <div>hello world</div>
      <Button onClick={logout}>logout</Button>
      <Button
        onClick={() => {
          void AFConfig?.service?.documentService.openDocument('test');
        }}
      >
        get document
      </Button>
      {children}
    </div>
  );
}

export default Layout;
