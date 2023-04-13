import { SettingsSvg } from '$app/components/_shared/svg/SettingsSvg';
import { useBoardToolbar } from '$app/components/board/BoardToolbar.hooks';
import { BoardSettingsPopup } from '$app/components/board/BoardSettingsPopup';
import { BoardFieldsPopup } from '$app/components/board/BoardFieldsPopup';
import { BoardGroupFieldsPopup } from '$app/components/board/BoardGroupFieldsPopup';

export const BoardToolbar = ({ title }: { title: string }) => {
  const { showSettings, showAllFields, showGroupFields, onSettingsClick, onFieldsClick, onGroupClick, hidePopup } =
    useBoardToolbar();

  return (
    <div className={'relative flex items-center gap-2'}>
      <div className={'text-xl font-semibold'}>{title}</div>
      <button onClick={() => onSettingsClick()} className={'h-5 w-5'}>
        <SettingsSvg></SettingsSvg>
      </button>
      {showSettings && (
        <BoardSettingsPopup
          hidePopup={hidePopup}
          onFieldsClick={onFieldsClick}
          onGroupClick={onGroupClick}
        ></BoardSettingsPopup>
      )}
      {showAllFields && <BoardFieldsPopup hidePopup={hidePopup}></BoardFieldsPopup>}
      {showGroupFields && <BoardGroupFieldsPopup hidePopup={hidePopup}></BoardGroupFieldsPopup>}
    </div>
  );
};
