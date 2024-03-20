import React, { useEffect, useState } from 'react';
import { TextField } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { isUrl } from '$app/utils/open_url';

function LinkEditInput({
  link,
  setLink,
  inputRef,
}: {
  link: string;
  setLink: (link: string) => void;
  inputRef: React.RefObject<HTMLElement>;
}) {
  const { t } = useTranslation();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isUrl(link)) {
      setError(null);
      return;
    }

    setError(t('editor.incorrectLink'));
  }, [link, t]);

  return (
    <form>
      <TextField
        variant={'outlined'}
        size={'small'}
        error={!!error}
        helperText={error}
        autoFocus={true}
        value={link}
        onChange={(e) => setLink(e.target.value)}
        spellCheck={false}
        inputRef={inputRef}
        className={'my-1 p-0'}
        placeholder={'https://example.com'}
        fullWidth={true}
      />
    </form>
  );
}

export default LinkEditInput;
