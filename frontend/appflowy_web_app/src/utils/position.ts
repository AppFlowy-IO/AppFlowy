export function inView(dom: HTMLElement, container: HTMLElement) {
  const domRect = dom.getBoundingClientRect();
  const containerRect = container.getBoundingClientRect();

  if (!domRect || !containerRect) return true;

  return domRect?.bottom <= containerRect?.bottom && domRect?.top >= containerRect?.top;
}

export function getDistanceEdge(dom: HTMLElement, container: HTMLElement) {
  const domRect = dom.getBoundingClientRect();
  const containerRect = container.getBoundingClientRect();

  if (!domRect || !containerRect) return 0;

  const distanceTop = domRect?.top - containerRect?.top;
  const distanceBottom = domRect?.bottom - containerRect?.bottom;

  return Math.abs(distanceTop) < Math.abs(distanceBottom) ? distanceTop : distanceBottom;
}
