import IndexedDBCleaner from '@/components/_shared/modal/IndexedDBCleaner';
import NormalModal from '@/components/_shared/modal/NormalModal';
import React from 'react';
import {
  DialogContent,
  DialogContentText,
  List,
  ListItem,
  ListItemText,
} from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as ErrorIcon } from '@/assets/error.svg';

const CacheClearingDialog = ({ open, onClose }: { open: boolean; onClose: () => void }) => {
  const { t } = useTranslation();

  return (
    <NormalModal
      title={<div className={'text-left font-semibold'}>{t('settings.manageDataPage.cache.title')}</div>
      }
      open={open} onClose={onClose}
      onOk={onClose}
      cancelButtonProps={{
        className: 'hidden',
      }}
    >
      <DialogContent>
        <DialogContentText>
          You are about to clear the IndexedDB cache. This action may have the following effects:
        </DialogContentText>
        <List>
          <ListItem className={'gap-2'}>
            <ErrorIcon className={'text-function-error'} />
            <ListItemText className={'flex-1'} primary="Slower document loading times initially" />
          </ListItem>
          <ListItem className={'gap-2'}>
            <ErrorIcon className={'text-function-error w-4 h-4'} />
            <ListItemText className={'flex-1'} primary="Temporary decrease in application performance" />
          </ListItem>
          <ListItem className={'gap-2'}>
            <ErrorIcon className={'text-function-error w-4 h-4'} />
            <ListItemText className={'flex-1'} primary="Need to re-download and re-process some data" />
          </ListItem>
          <ListItem className={'gap-2'}>
            <ErrorIcon className={'text-function-error w-4 h-4'} />
            <ListItemText
              className={'flex-1'} primary="Possible loss of offline functionality until data is re-cached"
            />
          </ListItem>
          <ListItem className={'gap-2'}>
            <ErrorIcon className={'text-function-error w-4 h-4'} />
            <ListItemText
              className={'flex-1'}
              primary="Frequent deletions may cause the browser to crash. If the data cannot be loaded, please try restarting the browser."
            />
          </ListItem>
        </List>
        <DialogContentText>
          Are you sure you want to proceed?
        </DialogContentText>
        {open && <IndexedDBCleaner />}

      </DialogContent>
    </NormalModal>
  );
};

export default CacheClearingDialog;