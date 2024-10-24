import { YDoc } from '@/application/types';
import { PublishProvider } from '@/application/publish';

import { AFConfigContext } from '@/components/main/app.hooks';

import PublishLayout from '@/components/publish/PublishLayout';
import PublishMobileLayout from '@/components/publish/PublishMobileLayout';
import { getPlatform } from '@/utils/platform';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import NotFound from '@/components/error/NotFound';
import { useSearchParams } from 'react-router-dom';

export interface PublishViewProps {
  namespace: string;
  publishName: string;
}

export function PublishView ({ namespace, publishName }: PublishViewProps) {
  const [doc, setDoc] = useState<YDoc | undefined>();
  const [notFound, setNotFound] = useState<boolean>(false);
  const service = useContext(AFConfigContext)?.service;
  const openPublishView = useCallback(async () => {
    let doc;

    setNotFound(false);
    setDoc(undefined);
    try {
      doc = await service?.getPublishView(namespace, publishName);
    } catch (e) {
      setNotFound(true);
      return;
    }

    setDoc(doc);
  }, [namespace, publishName, service]);

  useEffect(() => {
    void openPublishView();
  }, [openPublishView]);

  const [search] = useSearchParams();

  const isTemplate = search.get('template') === 'true';
  const isTemplateThumb = isTemplate && search.get('thumbnail') === 'true';

  useEffect(() => {
    if (!isTemplateThumb) return;
    document.documentElement.setAttribute('thumbnail', 'true');
  }, [isTemplateThumb]);

  if (notFound && !doc) {
    return <NotFound />;
  }

  return (
    <PublishProvider
      isTemplateThumb={isTemplateThumb}
      isTemplate={isTemplate}
      namespace={namespace}
      publishName={publishName}
    >
      {getPlatform().isMobile ? <PublishMobileLayout doc={doc} /> : <PublishLayout
        isTemplateThumb={isTemplateThumb}
        isTemplate={isTemplate}
        doc={doc}
      />}

    </PublishProvider>
  );
}

export default PublishView;
