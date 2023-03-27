import { useEffect } from 'react';
import { DocumentData } from '$app/interfaces/document';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { documentActions } from '$app/stores/reducers/document/slice';

export function useParseTree(documentData: DocumentData) {
  const dispatch = useAppDispatch();
  const { blocks, ytexts, yarrays } = documentData;

  useEffect(() => {
    dispatch(
      documentActions.createTree({
        nodes: blocks,
        delta: ytexts,
        children: yarrays,
      })
    );

    return () => {
      dispatch(documentActions.clear());
    };
  }, [documentData]);
}
