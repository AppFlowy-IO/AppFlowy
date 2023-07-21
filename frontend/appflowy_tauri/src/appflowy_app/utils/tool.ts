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

export function throttle(fn: (...args: any[]) => void, delay: number, immediate = true) {
  let timeout: NodeJS.Timeout | null = null;

  return (...args: any[]) => {
    if (!timeout) {
      timeout = setTimeout(() => {
        timeout = null;
        !immediate && fn.apply(undefined, args);
      }, delay);
      immediate && fn.apply(undefined, args);
    }
  };
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
