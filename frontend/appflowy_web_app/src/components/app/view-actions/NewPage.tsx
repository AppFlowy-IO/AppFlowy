import { ViewLayout } from '@/application/types';
import { ReactComponent as Add } from '@/assets/add_circle.svg';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useAppOutline } from '@/components/app/app.hooks';
import SpaceList from '@/components/publish/header/duplicate/SpaceList';
import { Button } from '@mui/material';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function NewPage () {
  const { t } = useTranslation();
  const [open, setOpen] = React.useState<boolean>(false);
  const [loading, setLoading] = React.useState<boolean>(false);
  const [selectedSpaceId, setSelectedSpaceId] = React.useState<string>('');
  const outline = useAppOutline();
  const spaceList = useMemo(() => {
    if (!outline) return [];

    return outline.map(view => {
      return {
        id: view.view_id,
        extra: JSON.stringify(view.extra),
        name: view.name,
        isPrivate: view.is_private,
      };
    });
  }, [outline]);

  const onClose = React.useCallback(() => {
    setOpen(false);
  }, []);

  const {
    addPage,
    openPageModal,
  } = useAppHandlers();

  const handleAddPage = useCallback(async () => {
    if (!addPage || !openPageModal || !selectedSpaceId) return;
    setLoading(true);
    try {
      const viewId = await addPage(selectedSpaceId, {
        layout: ViewLayout.Document,
      });

      openPageModal(viewId);
      onClose();
      // eslint-disable-next-line
    } catch (e: any) {

      notify.error(e.message);
    } finally {
      setLoading(false);

    }
  }, [addPage, openPageModal, selectedSpaceId, onClose]);

  return (
    <div className={'w-full px-[10px]'}>
      <Button
        onClick={() => setOpen(true)}
        startIcon={<Add className={'w-5 h-5'} />}
        size={'small'}
        className={'justify-start w-full hover:bg-content-blue-50'}
        color={'inherit'}
      >
        {t('newPageText')}
      </Button>
      <NormalModal
        okText={t('button.add')}
        title={t('publish.duplicateTitle')}
        open={open}
        onClose={onClose}
        classes={{ container: 'items-start max-md:mt-auto max-md:items-center mt-[10%] ' }}
        onOk={handleAddPage}
        okLoading={loading}
      >
        <SpaceList
          loading={false}
          spaceList={spaceList}
          value={selectedSpaceId}
          onChange={setSelectedSpaceId}
        />
      </NormalModal>
    </div>
  );
}

export default NewPage;