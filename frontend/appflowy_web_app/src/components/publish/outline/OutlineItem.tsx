import { PublishViewInfo, ViewLayout } from '@/application/collab.type';
import { PublishContext } from '@/application/publish';
import { notify } from '@/components/_shared/notify';
import { renderCrumbIcon } from '@/components/publish/header/BreadcrumbItem';
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
    return (
      <div className={'flex h-fit w-full flex-col gap-2'}>
        <div
          className={
            'flex w-full items-center rounded-[8px] p-1.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
          }
        >
          {item.child_views?.length ? getIcon() : null}
          <div
            onClick={async () => {
              try {
                await navigateToView?.(item.view_id);
              } catch (e) {
                notify.error(t('publish.hasNotBeenPublished'));
              }
            }}
            className={'flex flex-1 cursor-pointer items-center gap-1'}
          >
            <div className={'icon'}>{renderCrumbIcon(item.icon?.value || String(item.layout))}</div>
            <div>{item.name}</div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className={'flex h-fit w-full flex-col'}>
      {renderItem(view)}
      <div
        className={'ml-9 flex transform flex-col gap-2 transition-all'}
        style={{
          height: isExpanded && view.child_views?.length ? 'auto' : 0,
          opacity: isExpanded && view.child_views?.length ? 1 : 0,
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
