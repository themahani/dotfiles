import type { Tally } from '../types'

export type Kind = 'tool' | 'mcp' | 'agent' | 'other'

export type Item = {
  key: string
  label: string
  tokens: number
  kind: Kind
  isEstimate: boolean
  color: string
  fill: string
}

export type Segment = Item & { cells: number }

export type Row = { name: string; total: string; segments: Segment[] }

export type View = { rows: Row[]; legend: Item[] }

export const EMPTY: Tally = { tools: {}, agents: {}, order: [] }

// Catppuccin Mocha, in the order tools first appear.
const PALETTE = [
  '#89b4fa', '#fab387', '#a6e3a1', '#cba6f7', '#f9e2af',
  '#94e2d5', '#f5c2e7', '#89dceb', '#f38ba8', '#b4befe',
]
const OTHER_COLOR = '#6c7086'

const FILL: Record<Exclude<Kind, 'other'>, string> = { tool: '█', mcp: '╲', agent: '⣿' }

// Fields every tool.call input carries that are not the tool's arguments.
const ENVELOPE = new Set(['tool', 'tool_use_id', 'agentId', 'requestMeta', 'consent'])

const ROW_LABEL = 7

export function isEmpty(tally: Tally): boolean {
  return Object.keys(tally.tools).length === 0 && Object.keys(tally.agents).length === 0
}

export function isTally(value: unknown): value is Tally {
  if (typeof value !== 'object' || value === null) return false
  const t = value as Record<string, unknown>
  return typeof t.tools === 'object' && t.tools !== null
    && typeof t.agents === 'object' && t.agents !== null
    && Array.isArray(t.order)
}

// Roughly 4 characters per token for English and code.
export function estimate(input: Readonly<Record<string, unknown>>, text: string | undefined): number {
  const args: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(input)) {
    if (!ENVELOPE.has(key)) args[key] = value
  }
  return Math.ceil((JSON.stringify(args).length + (text?.length ?? 0)) / 4)
}

function remember(order: string[], key: string): string[] {
  return order.includes(key) ? order : [...order, key]
}

export function addTool(tally: Tally, tool: string, tokens: number): Tally {
  return {
    ...tally,
    tools: { ...tally.tools, [tool]: (tally.tools[tool] ?? 0) + tokens },
    order: remember(tally.order, `tool:${tool}`),
  }
}

function agentKey(type: string | null): string {
  return `agent:${type ?? 'subagent'}`
}

export function nameAgent(tally: Tally, agentId: string, type: string): Tally {
  const agent = tally.agents[agentId] ?? { type: null, tokens: 0 }
  if (agent.type === type) return tally
  return {
    ...tally,
    agents: { ...tally.agents, [agentId]: { ...agent, type } },
    order: remember(tally.order, agentKey(type)),
  }
}

export function addAgent(tally: Tally, agentId: string, tokens: number): Tally {
  const agent = tally.agents[agentId] ?? { type: null, tokens: 0 }
  return {
    ...tally,
    agents: { ...tally.agents, [agentId]: { ...agent, tokens: agent.tokens + tokens } },
    order: remember(tally.order, agentKey(agent.type)),
  }
}

// A final figure for an agent: keep whichever is larger, the live sum or it.
export function settleAgent(tally: Tally, agentId: string, tokens: number): Tally {
  const agent = tally.agents[agentId] ?? { type: null, tokens: 0 }
  if (tokens <= agent.tokens) return tally
  return addAgent(tally, agentId, tokens - agent.tokens)
}

export function compact(n: number): string {
  if (n < 1000) return String(n)
  if (n < 100_000) return `${(n / 1000).toFixed(1)}k`
  if (n < 999_500) return `${Math.round(n / 1000)}k`
  return `${(n / 1_000_000).toFixed(1)}M`
}

function mcpParts(tool: string): { server: string; name: string } | null {
  const parts = tool.split('__')
  if (parts[0] !== 'mcp' || parts.length < 3) return null
  return { server: parts.slice(1, -1).join('__'), name: parts[parts.length - 1] ?? tool }
}

function colorOf(order: string[], key: string): string {
  const index = order.indexOf(key)
  return index < 0 ? OTHER_COLOR : PALETTE[index % PALETTE.length] ?? OTHER_COLOR
}

function bySize(a: Item, b: Item): number {
  return b.tokens - a.tokens
}

export function toolItems(tally: Tally): Item[] {
  const mcpNames = new Map<string, number>()
  for (const tool of Object.keys(tally.tools)) {
    const mcp = mcpParts(tool)
    if (mcp) mcpNames.set(mcp.name, (mcpNames.get(mcp.name) ?? 0) + 1)
  }
  return Object.entries(tally.tools).map(([tool, tokens]): Item => {
    const key = `tool:${tool}`
    const mcp = mcpParts(tool)
    const label = mcp === null ? tool
      : (mcpNames.get(mcp.name) ?? 0) > 1 ? `${mcp.server}.${mcp.name}` : mcp.name
    const kind = mcp === null ? 'tool' : 'mcp'
    return { key, label, tokens, kind, isEstimate: true, color: colorOf(tally.order, key), fill: FILL[kind] }
  }).sort(bySize)
}

export function agentItems(tally: Tally): Item[] {
  const byType = new Map<string, number>()
  for (const agent of Object.values(tally.agents)) {
    const type = agent.type ?? 'subagent'
    byType.set(type, (byType.get(type) ?? 0) + agent.tokens)
  }
  return [...byType].filter(([, tokens]) => tokens > 0).map(([type, tokens]): Item => {
    const key = agentKey(type === 'subagent' ? null : type)
    return { key, label: type, tokens, kind: 'agent', isEstimate: false, color: colorOf(tally.order, key), fill: FILL.agent }
  }).sort(bySize)
}

function merge(items: Item[], fill: string): Item {
  return {
    key: 'other',
    label: 'other',
    tokens: items.reduce((sum, item) => sum + item.tokens, 0),
    kind: 'other',
    isEstimate: items.some(item => item.isEstimate),
    color: OTHER_COLOR,
    fill,
  }
}

// Fills `width` cells: every segment gets one, the rest go by share of
// tokens. Segments past what fits merge into one `other` at the end.
export function layout(items: Item[], width: number, otherFill: string): Segment[] {
  if (width < 1 || items.length === 0) return []
  const shown = items.length <= width ? items : items.slice(0, width - 1)
  const rest = items.slice(shown.length)
  const all = rest.length > 0 ? [...shown, merge(rest, otherFill)] : shown
  const total = all.reduce((sum, item) => sum + item.tokens, 0)
  const spare = width - all.length
  const shares = all.map(item => (total > 0 ? (item.tokens / total) * spare : 0))
  const cells = shares.map(share => 1 + Math.floor(share))
  let left = width - cells.reduce((sum, n) => sum + n, 0)
  const byRemainder = shares
    .map((share, index) => ({ index, remainder: share - Math.floor(share) }))
    .sort((a, b) => b.remainder - a.remainder)
  for (const { index } of byRemainder) {
    if (left <= 0) break
    cells[index] = (cells[index] ?? 0) + 1
    left -= 1
  }
  return all.map((item, index) => ({ ...item, cells: cells[index] ?? 1 }))
}

export function legendText(item: Item): string {
  return `${item.fill} ${item.label} ${item.isEstimate ? '~' : ''}${compact(item.tokens)}`
}

export const LEGEND_GAP = 2

// The legend keeps the largest entries that fit in `width`; the rest, and
// any `other` segments, merge into one `other` entry at the end.
export function fitLegend(items: Item[], width: number): Item[] {
  const named = items.filter(item => item.kind !== 'other').sort(bySize)
  const others = items.filter(item => item.kind === 'other')
  const sizeOf = (list: Item[]) =>
    list.reduce((sum, item) => sum + legendText(item).length, 0) + LEGEND_GAP * Math.max(0, list.length - 1)
  for (let count = named.length; count >= 0; count -= 1) {
    const rest = [...named.slice(count), ...others]
    const list = rest.length > 0 ? [...named.slice(0, count), merge(rest, '█')] : named
    if (sizeOf(list) <= width) return list
  }
  return []
}

function total(items: Item[]): string {
  const sum = items.reduce((n, item) => n + item.tokens, 0)
  return `${items.some(item => item.isEstimate) ? '~' : ''}${compact(sum)}`
}

// Plain data for the band: one row per non-empty kind, then the legend when
// a row is left for it.
export function draw(tally: Tally, columns: number, maxRows: number): View {
  const kinds = [
    { name: 'tools', items: toolItems(tally), otherFill: FILL.tool },
    { name: 'agents', items: agentItems(tally), otherFill: FILL.agent },
  ].filter(kind => kind.items.length > 0)
  const totals = kinds.map(kind => total(kind.items))
  const totalWidth = Math.max(0, ...totals.map(text => text.length))
  const barWidth = columns - ROW_LABEL - 1 - totalWidth
  const rows = kinds.slice(0, Math.max(0, maxRows)).map((kind, index) => ({
    name: kind.name.padEnd(ROW_LABEL),
    total: (totals[index] ?? '').padStart(totalWidth),
    segments: layout(kind.items, barWidth, kind.otherFill),
  }))
  const legend = rows.length < maxRows ? fitLegend(rows.flatMap(row => row.segments), columns) : []
  return { rows, legend }
}
