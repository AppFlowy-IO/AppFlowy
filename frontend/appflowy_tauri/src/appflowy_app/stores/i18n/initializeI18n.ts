import i18n from 'i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import { initReactI18next } from 'react-i18next';
import en from '../../../../../appflowy_flutter/assets/translations/en.json';
import ar_SA from '../../../../../appflowy_flutter/assets/translations/ar-SA.json';
import ca_ES from '../../../../../appflowy_flutter/assets/translations/ca-ES.json';
import de_DE from '../../../../../appflowy_flutter/assets/translations/de-DE.json';
import es_VE from '../../../../../appflowy_flutter/assets/translations/es-VE.json';
import eu_ES from '../../../../../appflowy_flutter/assets/translations/eu-ES.json';
import fr_CA from '../../../../../appflowy_flutter/assets/translations/fr-CA.json';
import fr_FR from '../../../../../appflowy_flutter/assets/translations/fr-FR.json';
import hu_HU from '../../../../../appflowy_flutter/assets/translations/hu-HU.json';
import id_ID from '../../../../../appflowy_flutter/assets/translations/id-ID.json';
import it_IT from '../../../../../appflowy_flutter/assets/translations/it-IT.json';
import ja_JP from '../../../../../appflowy_flutter/assets/translations/ja-JP.json';
import ko_KR from '../../../../../appflowy_flutter/assets/translations/ko-KR.json';
import pl_PL from '../../../../../appflowy_flutter/assets/translations/pl-PL.json';
import pt_BR from '../../../../../appflowy_flutter/assets/translations/pt-BR.json';
import pt_PT from '../../../../../appflowy_flutter/assets/translations/pt-PT.json';
import ru_Ru from '../../../../../appflowy_flutter/assets/translations/ru-RU.json';
import sv from '../../../../../appflowy_flutter/assets/translations/sv.json';
import tr_TR from '../../../../../appflowy_flutter/assets/translations/tr-TR.json';
import zh_CN from '../../../../../appflowy_flutter/assets/translations/zh-CN.json';
import zh_TW from '../../../../../appflowy_flutter/assets/translations/zh-TW.json';

export default function () {
  void i18n
    .use(LanguageDetector)
    .use(initReactI18next)
    .init({
      resources: {
        en: { translation: en },
        'ar-SA': { translation: ar_SA },
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
