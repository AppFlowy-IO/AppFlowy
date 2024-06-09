import React, { useEffect } from 'react';
import { Alert, Snackbar } from '@mui/material';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useParams } from 'react-router-dom';
import { pagesActions } from '$app_reducers/pages/slice';
import Slide, { SlideProps } from '@mui/material/Slide';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import { useTrashActions } from '$app/components/trash/Trash.hooks';
import { openPage } from '$app_reducers/pages/async_actions';

function SlideTransition(props: SlideProps) {
  return <Slide {...props} direction='down' />;
}

function DeletePageSnackbar() {
  const firstViewId = useAppSelector((state) => {
    const workspaceId = state.workspace.currentWorkspaceId;
    const children = workspaceId ? state.pages.relationMap[workspaceId] : undefined;

    if (!children) return null;

    return children[0];
  });

  const showTrashSnackbar = useAppSelector((state) => state.pages.showTrashSnackbar);
  const dispatch = useAppDispatch();
  const { onPutback, onDelete } = useTrashActions();
  const { id } = useParams();

  const { t } = useTranslation();

  useEffect(() => {
    dispatch(pagesActions.setTrashSnackbar(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleBack = () => {
    if (firstViewId) {
      void dispatch(openPage(firstViewId));
    }
  };

  const handleClose = (toBack = true) => {
    dispatch(pagesActions.setTrashSnackbar(false));
    if (toBack) {
      handleBack();
    }
  };

  const handleRestore = () => {
    if (!id) return;
    void onPutback(id);
    handleClose(false);
  };

  const handleDelete = () => {
    if (!id) return;
    void onDelete([id]);

    if (!firstViewId) {
      handleClose(false);
      return;
    }

    handleBack();
  };

  return (
    <Snackbar
      anchorOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
      open={showTrashSnackbar}
      TransitionComponent={SlideTransition}
    >
      <Alert
        className={'flex items-center'}
        onClose={() => handleClose()}
        severity='info'
        variant='standard'
        sx={{
          width: '100%',
          '.MuiAlert-action': {
            padding: 0,
          },
        }}
      >
        <div className={'flex h-full w-full items-center justify-center gap-3'}>
          <span>{t('deletePagePrompt.text')}</span>
          <Button onClick={handleRestore} size={'small'} color={'primary'} variant={'text'}>
            {t('deletePagePrompt.restore')}
          </Button>
          <Button onClick={handleDelete} size={'small'} color={'error'} variant={'text'}>
            {t('deletePagePrompt.deletePermanent')}
          </Button>
        </div>
      </Alert>
    </Snackbar>
  );
}

export default DeletePageSnackbar;
