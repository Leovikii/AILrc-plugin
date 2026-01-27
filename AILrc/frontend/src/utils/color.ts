const colorCache = new Map<string, string>();

export function hexToRgba(hex: string, alpha: number): string {
    const cacheKey = `${hex}-${alpha.toFixed(2)}`;

    if (colorCache.has(cacheKey)) {
        return colorCache.get(cacheKey)!;
    }

    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    const result = `rgba(${r}, ${g}, ${b}, ${alpha})`;

    if (colorCache.size >= 100) {
        const firstKey = colorCache.keys().next().value;
        if (firstKey !== undefined) {
            colorCache.delete(firstKey);
        }
    }
    colorCache.set(cacheKey, result);

    return result;
}
