/// <reference types="vite/client" />
/// <reference types="vite-plugin-svgr/client" />
/// <reference types="vite-plugin-terminal/client" />
/// <reference types="cypress" />
/// <reference types="cypress-plugin-tab" />

interface Window {
  refresh_token: (token: string) => void;
  invalid_token: () => void;
  WebFont?: {
    load: (options: { google: { families: string[] } }) => void;
  };
  toast: {
    success: (message: string) => void;
    error: (message: string) => void;
    info: (message: string) => void;
    clear: () => void;
    default: (message: string) => void;
    warning: (message: string) => void;
  };

  Prism: {
    tokenize: (text: string, grammar: Prism.Grammar) => Prism.Token[];
    languages: Record<string, Prism.Grammar>;
    plugins: {
      autoloader: {
        languages_path: string;
      };
    };
  };
  hljs: {
    highlightAuto: (code: string) => { language: string };
  };
}

namespace Prism {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  interface Token {
    type: string;
    content: string | Token[];
    length: number;
  }
}
