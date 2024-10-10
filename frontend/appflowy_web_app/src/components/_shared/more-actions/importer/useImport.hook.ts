import { AFConfigContext } from '@/components/main/app.hooks';
import React, { useCallback, useContext, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';

export function useImport () {
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated || false;
  const [search, setSearch] = useSearchParams();
  const [loginOpen, setLoginOpen] = React.useState(false);
  const [open, setOpen] = React.useState(false);
  const url = window.location.href;
  const source = search.get('source');

  useEffect(() => {
    const isImport = search.get('action') === 'import';

    if (!isImport) return;

    setLoginOpen(!isAuthenticated);
    setOpen(isAuthenticated);
  }, [isAuthenticated, search, setSearch]);

  const handleLoginClose = useCallback(() => {
    setLoginOpen(false);
    setSearch((prev) => {
      prev.delete('action');
      prev.delete('source');
      return prev;
    });
  }, [setSearch]);

  const handleImportClose = useCallback(() => {
    setOpen(false);
    setSearch((prev) => {
      prev.delete('action');
      prev.delete('source');
      return prev;
    });
  }, [setSearch]);

  return {
    loginOpen,
    handleLoginClose,
    url,
    open,
    handleImportClose,
    source,
  };
}