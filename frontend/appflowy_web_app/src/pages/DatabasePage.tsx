import { Database, DatabaseRow } from '@/components/database';
import React from 'react';
import { useSearchParams } from 'react-router-dom';

function DatabasePage() {
  const [search] = useSearchParams();
  const rowId = search.get('r');

  if (rowId) {
    return <DatabaseRow rowId={rowId} />;
  }

  return <Database />;
}

export default DatabasePage;
