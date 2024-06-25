import React from 'react';
import { useParams } from 'react-router-dom';
import { PublishView } from '@/components/publish';

function PublishPage() {
  const { namespace, publishName } = useParams();

  if (!namespace || !publishName) return null;
  return <PublishView namespace={namespace} publishName={publishName} />;
}

export default PublishPage;
