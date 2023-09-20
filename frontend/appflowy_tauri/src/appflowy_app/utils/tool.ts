export function debounce(fn: (...args: any[]) => void, delay: number) {
  let timeout: NodeJS.Timeout;
  const debounceFn = (...args: any[]) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      fn.apply(undefined, args);
    }, delay);
  };

  debounceFn.cancel = () => {
    clearTimeout(timeout);
  };

  return debounceFn;
}

export function throttle<T extends (...args: any[]) => void = (...args: any[]) => void>(
  fn: T,
  delay: number,
  immediate = true,
): T {
  let timeout: NodeJS.Timeout | null = null;

  const run = (...args: Parameters<T>) => {
    if (!timeout) {
      timeout = setTimeout(() => {
        timeout = null;
        !immediate && fn.apply(undefined, args);
      }, delay);
      immediate && fn.apply(undefined, args);
    }
  };

  return run as T;
}

export function get<T = any>(obj: any, path: string[], defaultValue?: any): T {
  let value = obj;

  for (const prop of path) {
    if (value === undefined || typeof value !== 'object' || value[prop] === undefined) {
      return defaultValue !== undefined ? defaultValue : undefined;
    }

    value = value[prop];
  }

  return value;
}

export function set(obj: any, path: string[], value: any): void {
  let current = obj;

  for (let i = 0; i < path.length; i++) {
    const prop = path[i];

    if (i === path.length - 1) {
      current[prop] = value;
    } else {
      if (!current[prop]) {
        current[prop] = {};
      }

      current = current[prop];
    }
  }
}

export function isEqual<T>(value1: T, value2: T): boolean {
  if (typeof value1 !== 'object' || value1 === null || typeof value2 !== 'object' || value2 === null) {
    return value1 === value2;
  }

  if (Array.isArray(value1)) {
    if (!Array.isArray(value2) || value1.length !== value2.length) {
      return false;
    }

    for (let i = 0; i < value1.length; i++) {
      if (!isEqual(value1[i], value2[i])) {
        return false;
      }
    }

    return true;
  }

  const keys1 = Object.keys(value1);
  const keys2 = Object.keys(value2);

  if (keys1.length !== keys2.length) {
    return false;
  }

  for (const key of keys1) {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-expect-error
    if (!isEqual(value1[key], value2[key])) {
      return false;
    }
  }

  return true;
}

export function clone<T>(value: T): T {
  if (typeof value !== 'object' || value === null) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => clone(item)) as any;
  }

  const result: any = {};

  for (const key in value) {
    result[key] = clone(value[key]);
  }

  return result;
}

export function chunkArray<T>(array: T[], chunkSize: number) {
  const chunks = [];
  let i = 0;

  while (i < array.length) {
    chunks.push(array.slice(i, i + chunkSize));
    i += chunkSize;
  }

  return chunks;
}

/**
 * Creates an interval that repeatedly calls the given function with a specified delay.
 *
 * @param {Function} fn - The function to be called repeatedly.
 * @param {number} [delay] - The delay between function calls in milliseconds.
 * @param {Object} [options] - Additional options for the interval.
 * @param {boolean} [options.immediate] - Whether to immediately call the function when the interval is created. Default is true.
 *
 * @return {Function} - The function that runs the interval.
 * @return {Function.cancel} - A method to cancel the interval.
 *
 * @example
 * const log = interval((message) => console.log(message), 1000);
 *
 * log('foo'); // prints 'foo' every second.
 *
 * log('bar'); // change to prints 'bar' every second.
 *
 * log.cancel(); // stops the interval.
 */
export function interval<T extends (...args: any[]) => any = (...args: any[]) => any>(
  fn: T,
  delay?: number,
  options?: { immediate?: boolean },
): T & { cancel: () => void } {
  const { immediate = true } = options || {};
  let intervalId: NodeJS.Timer | null = null;
  let parameters: any[] = [];

  function run(...args: Parameters<T>) {
    parameters = args;

    if (intervalId !== null) {
      return;
    }

    immediate && fn.apply(undefined, parameters);
    intervalId = setInterval(() => {
      fn.apply(undefined, parameters);
    }, delay);
  }

  function cancel() {
    if (intervalId === null) {
      return;
    }

    clearInterval(intervalId);
    intervalId = null;
    parameters = [];
  }

  run.cancel = cancel;
  return run as T & { cancel: () => void };
}
