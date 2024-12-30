import { ViewIconType } from '@/application/types';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useAppView } from '@/components/app/app.hooks';
import { OutlinedInput } from '@mui/material';
import React, { useCallback, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';

function RenameModal({ open, onClose, viewId }: {
  open: boolean;
  onClose: () => void;
  viewId: string;
}) {
  const view = useAppView(viewId);

  const { t } = useTranslation();

  const [newValue, setNewValue] = React.useState('');
  const [loading, setLoading] = React.useState(false);

  const { updatePage } = useAppHandlers();

  const handleOk = useCallback(async () => {
    if (!view) return;
    if (!newValue) {
      notify.warning(t('web.error.pageNameIsEmpty'));
      return;
    }

    if (newValue === view.name) {
      return;
    }

    setLoading(true);
    try {
      await updatePage?.(viewId, {
        name: newValue, icon: view.icon || {
          ty: ViewIconType.Emoji,
          value: '',
        }, extra: view.extra || {},
      });
      onClose();
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    } finally {
      setLoading(false);
    }
  }, [newValue, t, updatePage, view, viewId, onClose]);

  useEffect(() => {
    if (view) {
      setNewValue(view.name);
    }
  }, [view]);

  const inputRef = useRef<HTMLInputElement | null>(null);

  return (
    <NormalModal
      keepMounted={false}
      okText={t('button.save')}
      cancelText={t('button.cancel')}
      open={open}
      okLoading={loading}
      onClose={onClose}
      title={t('button.rename')}
      onOk={handleOk}
      PaperProps={{
        className: 'w-96 max-w-[70vw]',
      }}
      classes={{ container: 'items-start max-md:mt-auto max-md:items-center mt-[10%] ' }}
    >
      <OutlinedInput
        autoFocus
        size={'small'}
        placeholder={'Enter new name'}
        value={newValue}
        inputRef={(input: HTMLInputElement) => {
          if (!input) return;
          if (!inputRef.current) {
            setTimeout(() => {
              input.setSelectionRange(0, input.value.length);
            }, 100);
            inputRef.current = input;
          }

        }}
        onChange={e => setNewValue(e.target.value)}
        fullWidth
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            void handleOk();
          }
        }}
      />
    </NormalModal>
  );
}

export default RenameModal;