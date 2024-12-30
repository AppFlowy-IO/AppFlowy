export class Log {
  static error(...msg: unknown[]) {
    console.error(...msg);
  }
  static info(...msg: unknown[]) {
    console.info(...msg);
  }

  static debug(...msg: unknown[]) {
    console.debug(...msg);
  }

  static trace(...msg: unknown[]) {
    console.trace(...msg);
  }

  static warn(...msg: unknown[]) {
    console.warn(...msg);
  }
}
