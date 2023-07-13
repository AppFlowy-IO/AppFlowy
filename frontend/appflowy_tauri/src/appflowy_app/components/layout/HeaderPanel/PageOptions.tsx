import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { usePageOptions } from './PageOptions.hooks';
import { Button, IconButton, List } from '@mui/material';
import Popover from '@mui/material/Popover';
import { useCallback, useState } from 'react';
import MoreMenu from '$app/components/layout/HeaderPanel/MoreMenu';
import { useTranslation } from 'react-i18next';

enum PageOptionsEnum {
  Share = 'Share',
  More = 'More',
}
export const PageOptions = () => {
  const { t } = useTranslation();
  const { anchorEl, onOptionsClick, onClose } = usePageOptions();
  const open = Boolean(anchorEl);
  const [option, setOption] = useState<PageOptionsEnum>();
  const renderMenu = useCallback(() => {
    switch (option) {
      case PageOptionsEnum.Share:
        return <div>Share</div>;
      default:
        return <MoreMenu onClose={onClose} />;
    }
  }, [onClose, option]);

  return (
    <>
      <div className={'relative flex items-center gap-4'}>
        <Button
          variant={'contained'}
          onClick={(e) => {
            const el = e.currentTarget;

            setOption(PageOptionsEnum.Share);
            onOptionsClick(el);
          }}
        >
          {t('shareAction.buttonText')}
        </Button>

        <IconButton
          id='option-button'
          size={'small'}
          className={'h-8 w-8 rounded text-text-title hover:bg-fill-list-hover'}
          onClick={(e) => {
            const el = e.currentTarget;

            setOption(PageOptionsEnum.More);
            onOptionsClick(el);
          }}
        >
          <Details2Svg></Details2Svg>
        </IconButton>
      </div>
      <Popover
        open={open}
        anchorEl={anchorEl}
        onClose={onClose}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
      >
        <List>{renderMenu()}</List>
      </Popover>
    </>
  );
};
