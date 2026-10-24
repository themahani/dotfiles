export type AgentTally = { type: string | null; tokens: number }

export type Tally = {
  // Estimated tokens per tool name, main loop only.
  tools: Record<string, number>
  // Real tokens per subagent id.
  agents: Record<string, AgentTally>
  // Segment keys in first-use order; a key's index picks its color.
  order: string[]
}

declare module 'claude-code' {
  interface PluginState {
    'token-bar': { tally: Tally; isHidden: boolean }
  }
}
