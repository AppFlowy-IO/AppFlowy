import { View, ViewLayout } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import { useAppHandlers } from '@/components/app/app.hooks';
import { Button } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function AddPageActions({ view, onClose }: {
  view: View;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const {
    addPage,
    openPageModal,
  } = useAppHandlers();

  const handleAddPage = useCallback(async (layout: ViewLayout, name?: string) => {
    if (!addPage || !openPageModal) return;
    notify.default(
      <span>
        <CircularProgress size={20}/>
        <span className={'ml-2'}>{t('document.creating')}</span>
      </span>,
    );
    try {
      const viewId = await addPage(view.view_id, { layout, name });

      openPageModal(viewId);
      notify.clear();
      // eslint-disable-next-line
    } catch (e: any) {
      notify.clear();
      notify.error(e.message);
    }
  }, [addPage, openPageModal, t, view.view_id]);

  const actions: {
    label: string;
    icon: React.ReactNode;
    disabled?: boolean;
    onClick: (e: React.MouseEvent) => void;
  }[] = useMemo(() => [
    {
      label: t('document.menuName'),
      icon: <ViewIcon
        layout={ViewLayout.Document}
        size={'medium'}
      />,
      onClick: () => {
        void handleAddPage(ViewLayout.Document);
      },
    },
    {
      label: t('grid.menuName'),
      disabled: true,
      icon: <ViewIcon
        layout={ViewLayout.Grid}
        size={'medium'}
      />,
      onClick: () => {
        void handleAddPage(ViewLayout.Grid, 'Table');
      },
    },
    {
      label: t('board.menuName'),
      disabled: true,
      icon: <ViewIcon
        layout={ViewLayout.Board}
        size={'medium'}
      />,
      onClick: () => {
        void handleAddPage(ViewLayout.Board, 'Board');
      },
    },
    {
      label: t('calendar.menuName'),
      disabled: true,
      icon: <ViewIcon
        layout={ViewLayout.Calendar}
        size={'medium'}
      />,
      onClick: () => {
        void handleAddPage(ViewLayout.Calendar, 'Calendar');
      },
    },
  ], [handleAddPage, t]);

  return (
    <div className={'flex flex-col gap-2 w-full p-1.5 min-w-[230px]'}>
      {actions.map(action => (
        <Button
          key={action.label}
          size={'small'}
          disabled={action.disabled}
          onClick={(e) => {
            action.onClick(e);
            onClose();
          }}
          className={'px-3 py-1 justify-start'}
          color={'inherit'}
          startIcon={action.icon}
        >
          {action.label}
        </Button>
      ))}
    </div>
  );
}

export default AddPageActions;