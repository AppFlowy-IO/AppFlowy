import { Workspace } from '@/application/types';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/main/app.hooks';
import { Button, OutlinedInput } from '@mui/material';
import React, { useCallback, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';

function RenameWorkspace ({ workspace, onUpdated }: {
  workspace: Workspace;
  onUpdated: (name: string) => void;
}) {
  const { t } = useTranslation();

  const service = useService();
  const [loading, setLoading] = React.useState(false);
  const [name, setName] = React.useState(workspace.name);
  const [open, setOpen] = React.useState(false);

  const handleUpdate = useCallback(async () => {
    if (!service) return;

    setLoading(true);
    try {
      await service.updateWorkspace(workspace.id, {
        workspace_name: name,
      });

      setOpen(false);
      onUpdated(name);
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    } finally {
      setLoading(false);
    }
  }, [onUpdated, name, service, workspace.id]);

  const inputRef = useRef<HTMLInputElement | null>(null);

  return (
    <>
      <Button
        color={'inherit'}
        size={'small'}
        className={'w-full justify-start'}
        onClick={(e) => {
          e.stopPropagation();
          e.preventDefault();
          setOpen(true);
        }}
        startIcon={
          <EditIcon />
        }
      >
        {t('button.rename')}
      </Button>
      <NormalModal
        disableRestoreFocus={true}
        disableAutoFocus={false}
        title={t('workspace.renameWorkspace')}
        open={open}
        onClose={() => setOpen(false)}
        okLoading={loading}
        onOk={handleUpdate}
        okText={t('button.save')}
        PaperProps={{
          className: 'w-96 max-w-[70vw]',
        }}
        classes={{ container: 'items-start max-md:mt-auto max-md:items-center mt-[10%] ' }}
      >
        <OutlinedInput
          autoFocus
          size={'small'}
          placeholder={'Enter workspace name'}
          value={name}
          inputRef={(input: HTMLInputElement) => {
            if (!input) return;
            if (!inputRef.current) {
              setTimeout(() => {
                input.setSelectionRange(0, input.value.length);
              }, 100);
              inputRef.current = input;
            }

          }}
          onChange={e => setName(e.target.value)}
          fullWidth
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              void handleUpdate();
            }
          }}
        />
      </NormalModal>
    </>
  );
}

export default RenameWorkspace;