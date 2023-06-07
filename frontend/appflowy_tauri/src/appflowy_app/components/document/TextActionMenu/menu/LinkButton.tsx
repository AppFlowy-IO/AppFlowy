import React, { useCallback, useContext } from 'react';
import LinkIcon from '@mui/icons-material/AddLink';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { newLinkThunk } from '$app_reducers/document/async-actions/link';

function LinkButton() {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
  const onClick = useCallback(() => {
    if (!controller) return;
    dispatch(
      newLinkThunk({
        controller,
      })
    );
  }, [controller, dispatch]);
  return (
    <div onClick={onClick} className={'flex cursor-pointer items-center justify-center px-1 text-[0.8rem]'}>
      <LinkIcon
        sx={{
          fontSize: '1.2rem',
          marginRight: '0.25rem',
        }}
      />
      <div className={'underline'}>Link</div>
    </div>
  );
}

export default LinkButton;
