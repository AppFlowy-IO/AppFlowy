import { View, ViewLayout } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { filterOutByCondition } from '@/components/_shared/outline/utils';
import { Popover } from '@/components/_shared/popover';
import { useAppHandlers, useAppOutline } from '@/components/app/app.hooks';
import SpaceItem from '@/components/app/outline/SpaceItem';
import { IconButton, OutlinedInput, Tooltip } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React, { useMemo } from 'react';
import { ReactComponent as SearchOutlined } from '@/assets/search.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as MoveIcon } from '@/assets/move_down.svg';

function MovePagePopover ({
  viewId,
  onMoved,
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

  const renderExtra = React.useCallback(({ hovered, view }: {
    hovered: boolean;
    view: View
  }) => {
    if (!hovered) return null;
    return <Tooltip
      disableInteractive={true}
      title={t('disclosureAction.moveTo') + `: ${view.name || t('menuAppHeader.defaultNewPageName')}`}
    ><IconButton
      size={'small'}
      className={'move-to-icon mx-2'}
      onClick={async () => {
        try {
          await movePage?.(viewId, view.view_id);
          props.onClose?.();
          onMoved?.();
          // eslint-disable-next-line
        } catch (e: any) {
          notify.error(e.message);
        }
      }}
    >
      <MoveIcon />
    </IconButton></Tooltip>;
  }, [movePage, onMoved, props, t, viewId]);

  return (
    <Popover {...props}>
      <div className={'flex folder-views w-full flex-1 flex-col gap-1 py-[10px] px-[10px]'}>
        <OutlinedInput
          startAdornment={<SearchOutlined className={'h-6 h-6'} />}
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
            className: 'px-2 py-1.5 text-base',
          }}
          className={'search-emoji-input'}
          placeholder={t('search.label')}
        />
        {views.map((view) => <SpaceItem
          view={view}
          key={view.view_id}
          width={268}
          expandIds={expandViewIds}
          toggleExpand={toggleExpandView}
          renderExtra={renderExtra}
        />)}
      </div>
    </Popover>
  );
}

export default MovePagePopover;