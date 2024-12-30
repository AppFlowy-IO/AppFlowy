import { notify } from '@/components/_shared/notify';
import { copyTextToClipboard } from '@/utils/copy';
import { Button, OutlinedInput, Tooltip } from '@mui/material';
import React from 'react';
import { ReactComponent as CopyIcon } from '@/assets/link.svg';
import { ReactComponent as CheckIcon } from '@/assets/check_circle.svg';
import { useTranslation } from 'react-i18next';

function LinkPreview ({
  url,
}: {
  url: string;
}) {
  const [clickCopy, setClickCopy] = React.useState(false);

  const { t } = useTranslation();

  return (
    <div className={'flex'}>
      <OutlinedInput
        readOnly
        size={'small'}
        style={{
          borderBottomRightRadius: 0,
          borderTopRightRadius: 0,
        }}
        value={url}
        className={'flex-1'}
      />

      <Tooltip
        title={clickCopy ?
          t('message.copy.success') : t('grid.url.copy')
        } placement={'top'}
      >
        <Button
          size={'small'}
          style={{
            borderBottomRightRadius: 8,
            borderTopRightRadius: 8,
            borderLeft: 'none',
          }}
          className={'rounded-none min-w-0'}
          variant={'outlined'}
          color={'inherit'}
          onMouseLeave={() => {
            setClickCopy(false);
          }}
          onClick={async () => {
            setClickCopy(true);
            try {
              await copyTextToClipboard(url);
              notify.success(t('grid.url.copy'));
            } catch (_) {
              //do nothing
            }
          }}
        >
          {clickCopy ? <CheckIcon className={'w-6 h-6 text-function-success'} /> :
            <CopyIcon className={'w-6 h-6'} />}
        </Button>
      </Tooltip>
    </div>
  );
}

export default LinkPreview;