export function getToolLevel(xp: number): number {
    if (xp < 0) return 1;
    return Math.floor(Math.sqrt(xp / 100)) + 1;
}

export function getToolCost(toolId: string, currentLevel: number): number {
    // Simple geometric progression or lookup
    return 100 * Math.pow(1.5, currentLevel - 1);
}
