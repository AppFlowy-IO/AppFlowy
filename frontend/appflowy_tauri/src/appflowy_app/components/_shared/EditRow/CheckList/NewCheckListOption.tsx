import { SelectOptionCellBackendService } from '$app/stores/effects/database/cell/select_option_bd_svc';
import { useTranslation } from 'react-i18next';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';

export const NewCheckListOption = ({
  index,
  option,
  newOptions,
  setNewOptions,
  cellIdentifier,
}: {
  index: number;
  option: string;
  newOptions: string[];
  setNewOptions: (v: string[]) => void;
  cellIdentifier: CellIdentifier;
}) => {
  const { t } = useTranslation();

  const updateNewOption = (value: string) => {
    const newOptionsCopy = [...newOptions];
    newOptionsCopy[index] = value;
    setNewOptions(newOptionsCopy);
  };

  const onNewOptionKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Enter') {
      void onSaveNewOptionClick();
    }
  };

  const onSaveNewOptionClick = async () => {
    await new SelectOptionCellBackendService(cellIdentifier).createOption({ name: newOptions[index] });
    setNewOptions(newOptions.filter((_, i) => i !== index));
  };

  return (
    <div className={'flex cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-shade-6'}>
      <input
        onKeyDown={(e) => onNewOptionKeyDown(e as unknown as KeyboardEvent)}
        className={'min-w-0 flex-1 pl-7'}
        value={option}
        onChange={(e) => updateNewOption(e.target.value)}
      />
      <button
        onClick={() => onSaveNewOptionClick()}
        className={'flex items-center gap-2 rounded-lg bg-main-accent px-4 py-2 text-white hover:bg-main-hovered'}
      >
        {t('grid.selectOption.create')}
      </button>
    </div>
  );
};
