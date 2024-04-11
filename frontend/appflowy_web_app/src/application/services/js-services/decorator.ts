/**
 * @description:
 * * This is a decorator that can be used to read data from storage and fetch data from the server.
 * * If the data is already in storage, it will return the data from storage and fetch the data from the server in the background.
 *
 * @param getStorage A function that returns the data from storage. eg. `() => Promise<T | undefined>`
 *
 * @param setStorage A function that saves the data to storage. eg. `(data: T) => Promise<void>`
 *
 * @param fetchFunction A function that fetches the data from the server. eg. `(params: P) => Promise<T | undefined>`
 *
 * @returns: A function that returns the data from storage and fetches the data from the server in the background.
 */
export function asyncDataDecorator<P, T> (
  getStorage: () => Promise<T | undefined>,
  setStorage: (data: T) => Promise<void>,
  fetchFunction: (params: P) => Promise<T | undefined>,
) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    async function fetchData (params: P) {
      const data = await fetchFunction(params);

      if (!data) return;
      await setStorage(data);
      return data;
    }

    const originalMethod = descriptor.value;

    descriptor.value = async function (params: P) {
      const data = await getStorage();

      await originalMethod.apply(this, [params]);
      if (data) {
        void fetchData(params);
        return data;
      } else {
        return fetchData(params);
      }
    };

    return descriptor;
  };
}

export function afterSignInDecorator (successCallback: () => Promise<void>) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      await originalMethod.apply(this, args);
      await successCallback();
    };

    return descriptor;
  };
}