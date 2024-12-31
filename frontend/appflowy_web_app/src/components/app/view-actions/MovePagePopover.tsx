import { View, ViewLayout } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { filterOutByCondition } from '@/components/_shared/outline/utils';
import { Popover } from '@/components/_shared/popover';
import { useAppHandlers, useAppOutline } from '@/components/app/app.hooks';
import SpaceItem from '@/components/app/outline/SpaceItem';
import { Button, Divider, OutlinedInput } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React, { useMemo } from 'react';
import { ReactComponent as SearchOutlined } from '@/assets/search.svg';
import { useTranslation } from 'react-i18next';
import OutlineIcon from '@/components/_shared/outline/OutlineIcon';
import { ReactComponent as SelectedIcon } from '@/assets/selected.svg';

function MovePagePopover({
  viewId,
  onMoved,
  onClose,
  ...props
}: PopoverProps & {
  viewId: string;
  onMoved?: () => void;
}) {
  const outline = useAppOutline();
  const [search, setSearch] = React.useState<string>('');
  const {
    movePage,
  } = useAppHandlers();

  const views = useMemo(() => {
    if (!outline) return [];
    return filterOutByCondition(outline, (view) => ({
      remove: view.view_id === viewId || view.layout !== ViewLayout.Document || Boolean(search && !view.name.toLowerCase().includes(search.toLowerCase())),
    }));
  }, [outline, search, viewId]);
  const { t } = useTranslation();
  const [expandViewIds, setExpandViewIds] = React.useState<string[]>([]);
  const toggleExpandView = React.useCallback((id: string, isExpanded: boolean) => {
    setExpandViewIds((prev) => {
      return isExpanded ? [...prev, id] : prev.filter((v) => v !== id);
    });
  }, []);

  const [selectedViewId, setSelectedViewId] = React.useState<string | null>(null);

  const handleMoveTo = React.useCallback(async () => {
    if (selectedViewId) {
      try {
        await movePage?.(viewId, selectedViewId);
        onClose?.({}, 'backdropClick');
        onMoved?.();
        // eslint-disable-next-line
      } catch (e: any) {
        notify.error(e.message);
      }
    }
  }, [movePage, onMoved, onClose, selectedViewId, viewId]);

  const renderExtra = React.useCallback(({ view }: { view: View }) => {
    if (view.view_id !== selectedViewId) return null;
    return <SelectedIcon className={'w-5 h-5 text-fill-default mx-2'}/>;
  }, [selectedViewId]);

  return (
    <Popover {...props} onClose={onClose}>
      <div className={'flex folder-views w-[320px] flex-1 flex-col gap-1 py-[10px] px-[10px]'}>
        <OutlinedInput
          startAdornment={<SearchOutlined className={'h-4 w-4'}/>}
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
          }}
          autoFocus={true}
          fullWidth={true}
          size={'small'}
          autoCorrect={'off'}
          autoComplete={'off'}
          spellCheck={false}
          inputProps={{
            className: 'px-2 py-1.5 text-sm',
          }}
          className={'search-emoji-input'}
          placeholder={t('disclosureAction.movePageTo')}
        />
        <div className={'flex-1 max-h-[400px] overflow-x-hidden overflow-y-auto appflowy-custom-scroller'}>
          {views.map((view) => {
            const isExpanded = expandViewIds.includes(view.view_id);

            return <div key={view.view_id} className={'flex items-start gap-1'}>
              <div className={'h-[34px] flex items-center'}>
                <OutlineIcon isExpanded={isExpanded} setIsExpanded={(status) => {
                  toggleExpandView(view.view_id, status);
                }} level={0}/>
              </div>

              <SpaceItem
                view={view}
                key={view.view_id}
                width={268}
                expandIds={expandViewIds}
                toggleExpand={toggleExpandView}
                onClickView={viewId => {
                  toggleExpandView(viewId, !expandViewIds.includes(viewId));
                  setSelectedViewId(viewId);
                }}
                onClickSpace={setSelectedViewId}
                renderExtra={renderExtra}
              /></div>;
          })}
        </div>

        <Divider className={'mb-1'}/>
        <div className={'flex items-center justify-end'}>
          <Button onClick={handleMoveTo} size={'small'} color={'primary'} variant={'contained'}>
            {t('disclosureAction.move')}
          </Button>
        </div>
      </div>
    </Popover>
  );
}

export default MovePagePopover;