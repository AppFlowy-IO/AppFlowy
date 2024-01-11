import { useParams } from 'react-router-dom';

export function useShareConfig() {
  const params = useParams();
  const id = params.id;

  const showShareButton = !!id;

  return {
    showShareButton,
  };
}
