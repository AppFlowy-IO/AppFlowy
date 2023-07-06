import i18next from 'i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import { initReactI18next } from 'react-i18next';
import en from '../../../../appflowy_flutter/assets/translations/en.json';
import ar_SA from '../../../../appflowy_flutter/assets/translations/ar-SA.json';
import ca_ES from '../../../../appflowy_flutter/assets/translations/ca-ES.json';
import de_DE from '../../../../appflowy_flutter/assets/translations/de-DE.json';
import es_VE from '../../../../appflowy_flutter/assets/translations/es-VE.json';
import eu_ES from '../../../../appflowy_flutter/assets/translations/eu-ES.json';
import fr_CA from '../../../../appflowy_flutter/assets/translations/fr-CA.json';
import fr_FR from '../../../../appflowy_flutter/assets/translations/fr-FR.json';
import hu_HU from '../../../../appflowy_flutter/assets/translations/hu-HU.json';
import id_ID from '../../../../appflowy_flutter/assets/translations/id-ID.json';
import it_IT from '../../../../appflowy_flutter/assets/translations/it-IT.json';
import ja_JP from '../../../../appflowy_flutter/assets/translations/ja-JP.json';
import ko_KR from '../../../../appflowy_flutter/assets/translations/ko-KR.json';
import pl_PL from '../../../../appflowy_flutter/assets/translations/pl-PL.json';
import pt_BR from '../../../../appflowy_flutter/assets/translations/pt-BR.json';
import pt_PT from '../../../../appflowy_flutter/assets/translations/pt-PT.json';
import ru_Ru from '../../../../appflowy_flutter/assets/translations/ru-RU.json';
import sv from '../../../../appflowy_flutter/assets/translations/sv.json';
import tr_TR from '../../../../appflowy_flutter/assets/translations/tr-TR.json';
import zh_CN from '../../../../appflowy_flutter/assets/translations/zh-CN.json';
import zh_TW from '../../../../appflowy_flutter/assets/translations/zh-TW.json';

i18next
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    lng: 'en',
    debug: true,
    resources: {
      en: { translation: en },
      ar_SA: { translation: ar_SA },
      ca_ES: { translation: ca_ES },
      de_DE: { translation: de_DE },
      es_VE: { translation: es_VE },
      eu_ES: { translation: eu_ES },
      fr_CA: { translation: fr_CA },
      fr_FR: { translation: fr_FR },
      hu_HU: { translation: hu_HU },
      id_ID: { translation: id_ID },
      it_IT: { translation: it_IT },
      ja_JP: { translation: ja_JP },
      ko_KR: { translation: ko_KR },
      pl_PL: { translation: pl_PL },
      pt_BR: { translation: pt_BR },
      pt_PT: { translation: pt_PT },
      ru_RU: { translation: ru_Ru },
      sv_SE: { translation: sv },
      tr_TR: { translation: tr_TR },
      zh_CN: { translation: zh_CN },
      zh_TW: { translation: zh_TW },
    },
  });
