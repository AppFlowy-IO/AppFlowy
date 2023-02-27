import i18n from 'i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import { initReactI18next } from 'react-i18next';
import en from '../../../../../app_flowy/assets/translations/en.json';
import ca_ES from '../../../../../app_flowy/assets/translations/ca-ES.json';
import de_DE from '../../../../../app_flowy/assets/translations/de-DE.json';
import es_VE from '../../../../../app_flowy/assets/translations/es-VE.json';
import eu_ES from '../../../../../app_flowy/assets/translations/eu-ES.json';
import fr_CA from '../../../../../app_flowy/assets/translations/fr-CA.json';
import fr_FR from '../../../../../app_flowy/assets/translations/fr-FR.json';
import hu_HU from '../../../../../app_flowy/assets/translations/hu-HU.json';
import id_ID from '../../../../../app_flowy/assets/translations/id-ID.json';
import it_IT from '../../../../../app_flowy/assets/translations/it-IT.json';
import ja_JP from '../../../../../app_flowy/assets/translations/ja-JP.json';
import ko_KR from '../../../../../app_flowy/assets/translations/ko-KR.json';
import pl_PL from '../../../../../app_flowy/assets/translations/pl-PL.json';
import pt_BR from '../../../../../app_flowy/assets/translations/pt-BR.json';
import pt_PT from '../../../../../app_flowy/assets/translations/pt-PT.json';
import ru_Ru from '../../../../../app_flowy/assets/translations/ru-RU.json';
import sv from '../../../../../app_flowy/assets/translations/sv.json';
import tr_TR from '../../../../../app_flowy/assets/translations/tr-TR.json';
import zh_CN from '../../../../../app_flowy/assets/translations/zh-CN.json';
import zh_TW from '../../../../../app_flowy/assets/translations/zh-TW.json';

export default function () {
  void i18n
    .use(LanguageDetector)
    .use(initReactI18next)
    .init({
      resources: {
        en: { translation: en },
        'ca-ES': { translation: ca_ES },
        'de-DE': { translation: de_DE },
        'es-VE': { translation: es_VE },
        'eu-ES': { translation: eu_ES },
        'fr-CA': { translation: fr_CA },
        'fr-FR': { translation: fr_FR },
        'hu-HU': { translation: hu_HU },
        'id-ID': { translation: id_ID },
        'it-IT': { translation: it_IT },
        'ja-JP': { translation: ja_JP },
        'ko-KR': { translation: ko_KR },
        'pl-PL': { translation: pl_PL },
        'pt-BR': { translation: pt_BR },
        'pt-PT': { translation: pt_PT },
        'ru-RU': { translation: ru_Ru },
        sv: { translation: sv },
        'tr-TR': { translation: tr_TR },
        'zh-CN': { translation: zh_CN },
        'zh-TW': { translation: zh_TW },
      },
      fallbackLng: 'en',
      debug: true,

      interpolation: {
        escapeValue: false, // not needed for react as it escapes by default
      },
    });
}
