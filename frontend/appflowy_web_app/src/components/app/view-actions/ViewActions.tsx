import { View, ViewLayout } from '@/application/types';
import { Popover } from '@/components/_shared/popover';
import AddPageActions from '@/components/app/view-actions/AddPageActions';
import MorePageActions from '@/components/app/view-actions/MorePageActions';
import MoreSpaceActions from '@/components/app/view-actions/MoreSpaceActions';
import PageActions from '@/components/app/view-actions/PageActions';
import SpaceActions from '@/components/app/view-actions/SpaceActions';
import { PopoverProps } from '@mui/material/Popover';
import React, { useCallback, useMemo } from 'react';
import { useAppHandlers } from '@/components/app/app.hooks';
import { notify } from '@/components/_shared/notify';

const popoverProps: Partial<PopoverProps> = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
};

export function ViewActions({ view, hovered }: {
  view: View;
  hovered?: boolean;
}) {
  const isSpace = view?.extra?.is_space;
  const [popoverType, setPopoverType] = React.useState<{
    category: 'space' | 'page';
    type: 'more' | 'add';
  } | null>(null);
  const [anchorPosition, setAnchorPosition] = React.useState<undefined | {
    top: number;
    left: number;
  }>(undefined);
  const open = Boolean(anchorPosition);
  const handleClosePopover = () => {
    setAnchorPosition(undefined);
  };

  const {
    addPage,
    openPageModal,
  } = useAppHandlers();
  const handleAddPage = useCallback(async (layout: ViewLayout, name?: string) => {
    if (!addPage || !openPageModal) return;
    try {
      const viewId = await addPage(view.view_id, { layout, name });

      openPageModal(viewId);
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    }

  }, [addPage, openPageModal, view.view_id]);

  const handleClick = useCallback((e: React.MouseEvent, popoverType: {
    category: 'space' | 'page';
    type: 'more' | 'add';
  }) => {
    setPopoverType(popoverType);
    const rect = (e.target as HTMLElement).getBoundingClientRect();

    setAnchorPosition({ top: rect.bottom, left: rect.left });
  }, []);

  const renderButton = useMemo(() => {
    if (!hovered || !view) return null;
    if (isSpace) return <SpaceActions
      onClickAdd={async () => {
        // handleClick(e, { category: 'space', type: 'add' });
        await handleAddPage(ViewLayout.Document);
      }}
      onClickMore={(e) => {
        handleClick(e, { category: 'space', type: 'more' });
      }}
      view={view}
    />;
    return <PageActions
      onClickAdd={async () => {
        // handleClick(e, { category: 'page', type: 'add' });
        await handleAddPage(ViewLayout.Document);
      }}
      onClickMore={(e) => {
        handleClick(e, { category: 'page', type: 'more' });
      }}
      view={view}
    />;
  }, [handleClick, hovered, isSpace, view, handleAddPage]);

  const popoverContent = useMemo(() => {
    if (!popoverType) return null;

    if (popoverType.type === 'add') {
      return <AddPageActions
        onClose={() => {
          handleClosePopover();
        }}
        view={view}
      />;
    }

    if (popoverType.category === 'space') {
      return <MoreSpaceActions
        onClose={() => {
          handleClosePopover();
        }}
        view={view}
      />;
    } else {
      return <MorePageActions
        view={view}
        onClose={() => {
          handleClosePopover();
        }}
      />;
    }
  }, [popoverType, view]);

  return <div onClick={e => e.stopPropagation()}>
    {renderButton}
    <Popover
      {...popoverProps}
      keepMounted={false}
      open={open}
      anchorPosition={anchorPosition}
      onClose={handleClosePopover}
      anchorReference={'anchorPosition'}
      sx={{
        '& .MuiPopover-paper': {
          margin: '10px 0',
        },
      }}
    >
      {popoverContent}
    </Popover>
  </div>;

}

export default ViewActions;