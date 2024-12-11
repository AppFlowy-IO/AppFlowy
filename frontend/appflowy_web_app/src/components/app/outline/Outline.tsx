import { View } from '@/application/types';
import { getOutlineExpands, setOutlineExpands } from '@/components/_shared/outline/utils';
import DirectoryStructure from '@/components/_shared/skeleton/DirectoryStructure';
import { useAppHandlers, useAppOutline } from '@/components/app/app.hooks';
import SpaceItem from '@/components/app/outline/SpaceItem';
import React, { useCallback, Suspense } from 'react';
import { Favorite } from '@/components/app/favorite';

const ViewActions = React.lazy(() => import('@/components/app/view-actions/ViewActions'));

export function Outline({
  width,
}: {
  width: number;
}) {
  const outline = useAppOutline();
  const [expandViewIds, setExpandViewIds] = React.useState<string[]>(Object.keys(getOutlineExpands()));
  const toggleExpandView = useCallback((id: string, isExpanded: boolean) => {

    setOutlineExpands(id, isExpanded);
    setExpandViewIds((prev) => {
      return isExpanded ? [...prev, id] : prev.filter((v) => v !== id);
    });
  }, []);
  const renderActions = useCallback(({ hovered, view }: { hovered: boolean; view: View }) => {
    return <Suspense><ViewActions
      hovered={hovered}
      view={view}
    /></Suspense>;
  }, []);

  const {
    toView,
  } = useAppHandlers();

  const onClickView = useCallback((viewId: string) => {
    void toView(viewId);
  }, [toView]);

  return (
    <div className={'flex folder-views w-full flex-1 flex-col py-[10px] px-[10px]'}>
      <Favorite/>
      {!outline || outline.length === 0 ? <div
          style={{
            width: width - 20,
          }}
        ><DirectoryStructure/>
        </div> :
        outline.map((view) => <SpaceItem
          view={view}
          key={view.view_id}
          width={width - 20}
          renderExtra={renderActions}
          expandIds={expandViewIds}
          toggleExpand={toggleExpandView}
          onClickView={onClickView}
        />)}
    </div>
  );
}

export default Outline;