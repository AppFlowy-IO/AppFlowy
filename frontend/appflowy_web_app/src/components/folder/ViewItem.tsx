import { layoutMap, ViewLayout, YjsFolderKey } from '@/application/collab.type';
import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import Page from 'src/components/_shared/page/Page';

function ViewItem({ id }: { id: string }) {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  return (
    <div className={'cursor-pointer border-b border-line-border py-4 px-2'}>
      <Page
        onClick={(view) => {
          const layout = parseInt(view?.get(YjsFolderKey.layout) ?? '0') as ViewLayout;

          navigate(`${pathname}/${layoutMap[layout]}/${id}`);
        }}
        id={id}
      />
    </div>
  );
}

export default ViewItem;
