/* eslint-disable @typescript-eslint/no-explicit-any */

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
  options?: { immediate?: boolean }
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
