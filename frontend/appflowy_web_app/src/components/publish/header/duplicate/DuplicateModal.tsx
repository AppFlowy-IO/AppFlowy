import React from 'react';
import { useTranslation } from 'react-i18next';
import { NormalModal } from '@/components/_shared/modal';
import SelectWorkspace from '@/components/publish/header/duplicate/SelectWorkspace';
import { useLoadWorkspaces } from '@/components/publish/header/duplicate/useDuplicate';
import SpaceList from '@/components/publish/header/duplicate/SpaceList';
import { notify } from '@/components/_shared/notify';

function DuplicateModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { t } = useTranslation();

  const { workspaceList, spaceList, setSelectedSpaceId, setSelectedWorkspaceId, selectedWorkspaceId, selectedSpaceId } =
    useLoadWorkspaces();

  return (
    <NormalModal
      onCancel={onClose}
      okText={t('button.add')}
      title={t('publish.duplicateTitle')}
      open={open}
      onClose={onClose}
      onOk={async () => {
        // submit form
        notify.success(t('publish.duplicateSuccessfully'));
        onClose();
      }}
    >
      <div className={'flex flex-col gap-4'}>
        <SelectWorkspace workspaceList={workspaceList} value={selectedWorkspaceId} onChange={setSelectedWorkspaceId} />
        <SpaceList spaceList={spaceList} value={selectedSpaceId} onChange={setSelectedSpaceId} />
      </div>
    </NormalModal>
  );
}

export default DuplicateModal;
