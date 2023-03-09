export function debounce(fn: (...args: any[]) => void, delay: number) {
  let timeout: NodeJS.Timeout;
  return (...args: any[]) => {
    clearTimeout(timeout)
    timeout = setTimeout(()=>{
      fn.apply(this, args)
    }, delay)
  }
}
