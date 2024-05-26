import { useId } from '@/components/_shared/context-provider/IdProvider';
import { DatabaseHeader } from '@/components/database/components/header';
import React from 'react';
import { useSearchParams } from 'react-router-dom';
import DatabaseRow from '@/components/database/DatabaseRow';
import Database from '@/components/database/Database';

function DatabasePage() {
  const objectId = useId()?.objectId;
  const [search] = useSearchParams();
  const rowId = search.get('r');

  if (rowId) {
    return <DatabaseRow rowId={rowId} />;
  }

  return (
    <div className={'relative flex h-full w-full flex-col'}>
      <DatabaseHeader viewId={objectId} />
      <Database />
    </div>
  );
}

export default DatabasePage;
