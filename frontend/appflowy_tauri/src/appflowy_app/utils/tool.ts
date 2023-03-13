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
