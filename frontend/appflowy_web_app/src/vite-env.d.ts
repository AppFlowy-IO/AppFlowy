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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    success: (message: any) => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    error: (message: any) => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    info: (props: any) => void;
    clear: () => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    default: (message: any) => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    warning: (message: any) => void;
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
