import { View } from '@/application/types';
import OutlineItemContent from '@/components/_shared/outline/OutlineItemContent';
import React, { useCallback, useEffect, useMemo } from 'react';
import { ReactComponent as ChevronDownIcon } from '@/assets/chevron_down.svg';

function getOutlineExpands () {
  const expandView = localStorage.getItem('outline_expanded');

  try {
    return JSON.parse(expandView || '{}');
  } catch (e) {
    return {};
  }
}

function setOutlineExpands (viewId: string, isExpanded: boolean) {
  const expands = getOutlineExpands();

  if (isExpanded) {
    expands[viewId] = true;
  } else {
    delete expands[viewId];
  }

  localStorage.setItem('outline_expanded', JSON.stringify(expands));
}

function OutlineItem ({ view, level = 0, width, navigateToView, selectedViewId }: {
  view: View;
  width: number;
  level?: number;
  selectedViewId?: string;
  navigateToView?: (viewId: string) => Promise<void>
}) {
  const selected = selectedViewId === view.view_id;
  const [isExpanded, setIsExpanded] = React.useState(() => {
    return getOutlineExpands()[view.view_id] || false;
  });

  useEffect(() => {
    setOutlineExpands(view.view_id, isExpanded);
  }, [isExpanded, view.view_id]);

  const getIcon = useCallback(() => {
    if (isExpanded) {
      return (
        <button
          style={{
            paddingLeft: 1.125 * level + 'rem',
          }}
          onClick={() => {
            setIsExpanded(false);
          }}
          className={'opacity-50 hover:opacity-100'}
        >
          <ChevronDownIcon className={'h-4 w-4'} />
        </button>
      );
    }

    return (
      <button
        style={{
          paddingLeft: 1.125 * level + 'rem',
        }}
        className={'opacity-50 hover:opacity-100'}
        onClick={() => {
          setIsExpanded(true);
        }}
      >
        <ChevronDownIcon className={'h-4 w-4 -rotate-90 transform'} />
      </button>
    );
  }, [isExpanded, level]);

  const renderItem = useCallback((item: View) => {
    return (
      <div className={'flex h-fit my-0.5 w-full flex-col gap-2'}>
        <div
          style={{
            width,
            backgroundColor: selected ? 'var(--fill-list-hover)' : undefined,
          }}
          className={
            'flex items-center w-full gap-0.5 rounded-[8px] py-1.5 px-0.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
          }
        >
          {item.children?.length ? getIcon() : null}

          <OutlineItemContent item={item} navigateToView={navigateToView} level={level} setIsExpanded={setIsExpanded} />
        </div>
      </div>
    );
  }, [getIcon, level, navigateToView, selected, width]);

  const children = useMemo(() => view.children || [], [view.children]);

  const renderChildren = useMemo(() => {
    return <div
      className={'flex transform flex-col gap-2 transition-all'}
      style={{
        display: isExpanded ? 'block' : 'none',
      }}
    >
      {children
        .map((item, index) => (
          <OutlineItem
            selectedViewId={selectedViewId}
            navigateToView={navigateToView}
            level={level + 1}
            width={width}
            key={index}
            view={item}
          />
        ))}
    </div>;
  }, [children, isExpanded, level, navigateToView, selectedViewId, width]);

  return (
    <div className={'flex h-fit w-full flex-col'}>
      {renderItem(view)}
      {renderChildren}
    </div>
  );
}

export default OutlineItem;
