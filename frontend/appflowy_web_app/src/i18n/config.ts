import i18next from 'i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import { initReactI18next } from 'react-i18next';
import resourcesToBackend from 'i18next-resources-to-backend';

void i18next
  .use(resourcesToBackend((language: string) => import(`../@types/translations/${language}.json`)))
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    lng: 'en',
    defaultNS: 'translation',
    debug: false,
    fallbackLng: 'en',
  });
