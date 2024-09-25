import { useAppView } from '@/components/app/app.hooks';
import { useService } from '@/components/main/app.hooks';
import React, { useCallback, useEffect, useMemo } from 'react';

export function useLoadPublishInfo () {
  const view = useAppView();
  const [publishInfo, setPublishInfo] = React.useState<{ namespace: string, publishName: string }>();

  const service = useService();

  const loadPublishInfo = useCallback(async () => {
    if (!service || !view?.view_id) return;
    try {
      const res = await service.getPublishInfo(view?.view_id);

      setPublishInfo(res);
      // eslint-disable-next-line
    } catch (e: any) {
      // do nothing
    }
  }, [service, view?.view_id]);

  useEffect(() => {
    void loadPublishInfo();
  }, [loadPublishInfo]);

  const url = useMemo(() => {
    return `${window.origin}/${publishInfo?.namespace}/${publishInfo?.publishName}`;
  }, [publishInfo]);

  return { publishInfo, url };
}