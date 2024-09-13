export function saveRedirectTo (redirectTo: string) {
  localStorage.setItem('redirectTo', redirectTo);
}

export function getRedirectTo () {
  return localStorage.getItem('redirectTo');
}

export function clearRedirectTo () {
  localStorage.removeItem('redirectTo');
}

export const AUTH_CALLBACK_PATH = '/auth/callback';
export const AUTH_CALLBACK_URL = `${window.location.origin}${AUTH_CALLBACK_PATH}`;

export function withSignIn () {
  return function (
    // eslint-disable-next-line
    _target: any,
    _propertyKey: string,
    descriptor: PropertyDescriptor,
  ) {
    const originalMethod = descriptor.value;

    // eslint-disable-next-line
    descriptor.value = async function (args: { redirectTo: string }) {
      const redirectTo = args.redirectTo;

      saveRedirectTo(redirectTo);

      try {
        await originalMethod.apply(this, [args]);
      } catch (e) {
        console.error(e);
        return Promise.reject(e);
      }
    };

    return descriptor;
  };
}

export function afterAuth () {
  const redirectTo = getRedirectTo();

  if (redirectTo) {
    clearRedirectTo();
    window.location.href = redirectTo;
  }
}
