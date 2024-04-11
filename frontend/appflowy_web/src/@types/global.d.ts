export interface NotifyArgs {
  source: string;
  ty: number;
  id: string;
  payload?: Unit8Array;
  error?: Unit8Array;
}

declare global {
  interface Window {
    onFlowyNotify: (eventName: string, args: NotifyArgs) => void;
  }
}

export {};
