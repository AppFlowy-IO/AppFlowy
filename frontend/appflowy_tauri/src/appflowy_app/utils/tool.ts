export function debounce(fn: (...args: any[]) => void, delay: number) {
  let timeout: NodeJS.Timeout;
  return (...args: any[]) => {
    clearTimeout(timeout)
    timeout = setTimeout(()=>{
      // eslint-disable-next-line prefer-spread
      fn.apply(undefined, args)
    }, delay)
  }
}

export function get(obj: any, path: string[], defaultValue?: any) {
  let value = obj;
  for (const prop of path) {
    value = value[prop];
    if (value === undefined) {
      return defaultValue !== undefined ? defaultValue : undefined;
    }
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
