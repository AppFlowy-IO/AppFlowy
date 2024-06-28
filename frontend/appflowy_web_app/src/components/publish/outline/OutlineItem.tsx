import { PublishViewInfo, ViewLayout } from '@/application/collab.type';
import { PublishContext } from '@/application/publish';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import React, { useCallback, useContext } from 'react';
import { ReactComponent as ChevronDownIcon } from '@/assets/chevron_down.svg';
import { useTranslation } from 'react-i18next';

function OutlineItem({ view }: { view: PublishViewInfo }) {
  const [isExpanded, setIsExpanded] = React.useState(false);
  const getIcon = useCallback(() => {
    if (isExpanded) {
      return (
        <button
          onClick={() => {
            setIsExpanded(false);
          }}
        >
          <ChevronDownIcon className={'h-4 w-4'} />
        </button>
      );
    }

    return (
      <button
        onClick={() => {
          setIsExpanded(true);
        }}
      >
        <ChevronDownIcon className={'h-4 w-4 -rotate-90 transform'} />
      </button>
    );
  }, [isExpanded]);
  const { t } = useTranslation();

  const navigateToView = useContext(PublishContext)?.toView;
  const renderItem = (item: PublishViewInfo) => {
    const { icon, layout, name, view_id } = item;
    const hasChildren = Boolean(item.child_views?.length);

    return (
      <div
        style={{
          marginLeft: hasChildren ? '0' : '1.125rem',
        }}
        className={'flex h-fit flex-col gap-2'}
      >
        <div
          className={
            'flex w-full items-center gap-0.5 rounded-[8px] p-1.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
          }
        >
          {item.child_views?.length ? getIcon() : null}
          <div
            onClick={async () => {
              try {
                await navigateToView?.(view_id);
              } catch (e) {
                notify.error(t('publish.hasNotBeenPublished'));
              }
            }}
            className={'flex flex-1 cursor-pointer items-center gap-1 overflow-hidden'}
          >
            <div className={'icon'}>{icon?.value || <ViewIcon layout={layout} size={'small'} />}</div>
            <div className={'flex-1 truncate'}>{name}</div>
          </div>
        </div>
      </div>
    );
  };

  const hasChildren = Boolean(view.child_views?.length);

  return (
    <div className={'flex h-fit w-full flex-col'}>
      {renderItem(view)}
      <div
        className={'flex transform flex-col gap-2 transition-all'}
        style={{
          height: isExpanded && view.child_views?.length ? 'auto' : 0,
          opacity: isExpanded && view.child_views?.length ? 1 : 0,
          marginLeft: hasChildren ? '1.125rem' : '2.25rem',
        }}
      >
        {view.child_views
          ?.filter((view) => view.layout === ViewLayout.Document)
          ?.map((item, index) => (
            <OutlineItem key={index} view={item} />
          ))}
      </div>
    </div>
  );
}

export default OutlineItem;
