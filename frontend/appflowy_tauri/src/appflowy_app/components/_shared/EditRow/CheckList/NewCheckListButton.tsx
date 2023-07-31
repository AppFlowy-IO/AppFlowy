import AddSvg from '$app/components/_shared/svg/AddSvg';
import { useTranslation } from 'react-i18next';

export const NewCheckListButton = ({
  newOptions,
  setNewOptions,
}: {
  newOptions: string[];
  setNewOptions: (v: string[]) => void;
}) => {
  const { t } = useTranslation();

  const newOptionClick = () => {
    setNewOptions([...newOptions, '']);
  };

  return (
    <button
      onClick={() => newOptionClick()}
      className={'flex w-full items-center gap-2 rounded-lg px-2 py-2 hover:bg-shade-6'}
    >
      <i className={'h-5 w-5'}>
        <AddSvg></AddSvg>
      </i>
      <span>{t('grid.field.addOption')}</span>
    </button>
  );
};
