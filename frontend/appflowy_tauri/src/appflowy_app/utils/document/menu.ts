export function selectOptionByUpDown(isUp: boolean, selected: string | null, options: string[]) {
  const index = options.findIndex((option) => option === selected);

  let nextIndex = -1;

  if (isUp) {
    nextIndex = index - 1;
  } else {
    nextIndex = index + 1;
  }

  if (nextIndex < 0) {
    nextIndex = options.length - 1;
  } else if (nextIndex >= options.length) {
    nextIndex = 0;
  }

  const nextOption = options[nextIndex];

  return nextOption;
}
