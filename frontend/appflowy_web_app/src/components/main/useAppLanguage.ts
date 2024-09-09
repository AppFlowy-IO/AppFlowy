import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';

export function useAppLanguage() {
  const { i18n } = useTranslation();

  useEffect(() => {
    const detectLanguageChange = () => {
      const language = window.navigator.language;

      void i18n.changeLanguage(language);
    };

    detectLanguageChange();

    window.addEventListener('languagechange', detectLanguageChange);
    return () => {
      window.removeEventListener('languagechange', detectLanguageChange);
    };
  }, [i18n]);
}
