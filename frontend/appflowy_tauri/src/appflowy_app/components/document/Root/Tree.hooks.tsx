import { useEffect } from 'react';
import { DocumentData } from '$app/interfaces/document';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { documentActions } from '$app/stores/reducers/document/slice';

export function useParseTree(documentData: DocumentData) {
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(documentActions.create(documentData));

    return () => {
      dispatch(documentActions.clear());
    };
  }, [documentData]);
}
