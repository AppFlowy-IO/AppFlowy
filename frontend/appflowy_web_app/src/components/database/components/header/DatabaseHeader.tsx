import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import Title from './Title';
import React from 'react';

export function DatabaseHeader({ viewId }: { viewId: string }) {
  const { name, icon } = usePageInfo(viewId);

  return <Title name={name} icon={icon} />;
}

export default DatabaseHeader;
