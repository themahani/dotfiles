export type Part = { name: string; tokens: number }

// The context window as the band last measured it.
export type Snapshot = {
  // The window the categories measure against (the breakdown's rawMaxTokens).
  window: number
  // In-window categories in the engine's order, Messages among them.
  categories: Part[]
  // The compaction reserve, 0 when there is none.
  buffer: number
  // Estimated tokens per tool across its calls and results, in first-use order.
  tools: Part[]
}

declare module 'claude-code' {
  interface PluginState {
    'token-bar': { snapshot: Snapshot; isHidden: boolean }
  }
}
