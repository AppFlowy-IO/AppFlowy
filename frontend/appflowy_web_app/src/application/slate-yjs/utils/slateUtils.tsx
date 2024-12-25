import { Path } from 'slate';

export function findIndentPath (originalStart: Path, originalEnd: Path, newStart: Path): Path {
  // Find the common ancestor path
  const commonPath = Path.common(originalStart, originalEnd);

  // Calculate end's path relative to common ancestor
  const endRelativePath = originalEnd.slice(commonPath.length);

  // Calculate new common ancestor path by maintaining the same level difference
  const startToCommonLevels = originalStart.length - commonPath.length;
  const newCommonAncestor = newStart.slice(0, newStart.length - startToCommonLevels);

  // Append the relative path to new common ancestor
  return [...newCommonAncestor, ...endRelativePath];
}

export function findLiftPath (originalStart: Path, originalEnd: Path, newStart: Path): Path {
  // Same logic as findIndentPath
  const commonPath = Path.common(originalStart, originalEnd);
  const endRelativePath = originalEnd.slice(commonPath.length);
  const startToCommonLevels = originalStart.length - commonPath.length;
  const newCommonAncestor = newStart.slice(0, newStart.length - startToCommonLevels);

  return [...newCommonAncestor, ...endRelativePath];
}