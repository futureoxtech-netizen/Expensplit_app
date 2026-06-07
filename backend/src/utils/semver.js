/**
 * Minimal semantic-version comparison for "major.minor.patch" strings.
 * Ignores any pre-release / build suffix (e.g. "1.2.3+4" → 1.2.3).
 *
 * Returns: -1 if a < b, 0 if equal, 1 if a > b.
 */
export function compareVersions(a, b) {
  const parse = (v) =>
    String(v ?? '0')
      .trim()
      .split('+')[0]
      .split('-')[0]
      .split('.')
      .map((n) => parseInt(n, 10) || 0);

  const pa = parse(a);
  const pb = parse(b);
  const len = Math.max(pa.length, pb.length);
  for (let i = 0; i < len; i += 1) {
    const x = pa[i] ?? 0;
    const y = pb[i] ?? 0;
    if (x < y) return -1;
    if (x > y) return 1;
  }
  return 0;
}

export const isVersionLessThan = (a, b) => compareVersions(a, b) < 0;
