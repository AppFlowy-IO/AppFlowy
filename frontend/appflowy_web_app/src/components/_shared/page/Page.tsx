import { YView } from '@/application/collab.type';
import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import React from 'react';

export function Page({
  id,
  onClick,
  ...props
}: {
  id: string;
  onClick?: (view: YView) => void;
  style?: React.CSSProperties;
}) {
  const { view, icon, name } = usePageInfo(id);

  return (
    <div
      onClick={() => {
        onClick && view && onClick(view);
      }}
      className={'flex items-center justify-center gap-2 overflow-hidden'}
      {...props}
    >
      <div>{icon}</div>
      <div className={'flex-1 truncate'}>{name}</div>
    </div>
  );
}

export default Page;
