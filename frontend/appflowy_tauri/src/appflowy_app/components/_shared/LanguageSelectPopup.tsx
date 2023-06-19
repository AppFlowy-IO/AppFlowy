import { IPopupItem, PopupSelect } from './PopupSelect';
import i18n from 'i18next';

const supportedLanguages: { key: string; title: string }[] = [
  {
    key: 'en',
    title: 'English',
  },
  { key: 'ar-SA', title: 'ar-SA' },
  { key: 'ca-ES', title: 'ca-ES' },
  { key: 'de-DE', title: 'de-DE' },
  { key: 'es-VE', title: 'es-VE' },
  { key: 'eu-ES', title: 'eu-ES' },
  { key: 'fr-CA', title: 'fr-CA' },
  { key: 'fr-FR', title: 'fr-FR' },
  { key: 'hu-HU', title: 'hu-HU' },
  { key: 'id-ID', title: 'id-ID' },
  { key: 'it-IT', title: 'it-IT' },
  { key: 'ja-JP', title: 'ja-JP' },
  { key: 'ko-KR', title: 'ko-KR' },
  { key: 'pl-PL', title: 'pl-PL' },
  { key: 'pt-BR', title: 'pt-BR' },
  { key: 'pt-PT', title: 'pt-PT' },
  { key: 'ru-RU', title: 'ru-RU' },
  { key: 'sv', title: 'sv' },
  { key: 'tr-TR', title: 'tr-TR' },
  { key: 'zh-CN', title: 'zh-CN' },
  { key: 'zh-TW', title: 'zh-TW' },
];

export const LanguageSelectPopup = ({ onClose }: { onClose: () => void }) => {
  const items: IPopupItem[] = supportedLanguages.map<IPopupItem>((item) => ({
    onClick: () => {
      void i18n.changeLanguage(item.key);
      onClose();
    },
    title: item.title,
    icon: <></>,
  }));
  return (
    <PopupSelect
      items={items}
      className={'absolute top-full right-0 z-10 w-[200px]'}
      onOutsideClick={onClose}
      columns={2}
    ></PopupSelect>
  );
};
