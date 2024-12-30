import { AsTemplate } from '@/components/as-template';
import NotFound from '@/components/error/NotFound';
import React, { useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';

function AsTemplatePage () {
  const [searchParams] = useSearchParams();

  const viewId = useMemo(() => searchParams.get('viewId'), [searchParams]);
  const viewUrl = useMemo(() => searchParams.get('viewUrl'), [searchParams]);
  const viewName = useMemo(() => {
    const name = searchParams.get('viewName');

    if (name) {
      return decodeURIComponent(name);
    }

    return '';
  }, [searchParams]);

  if (!viewUrl || !viewId) return <NotFound />;
  return (
    <div className={'h-screen w-screen bg-bg-base overflow-hidden p-10'}>
      <AsTemplate viewId={viewId} viewUrl={viewUrl} viewName={viewName} />
    </div>
  );
}

export default AsTemplatePage;