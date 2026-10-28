import type { ContextCategory } from 'claude-code'

import type { Part, Snapshot } from '../types'

export type Kind = 'category' | 'tool' | 'mcp' | 'text' | 'room' | 'other'

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

export const EMPTY: Snapshot = { window: 0, categories: [], buffer: 0, tools: [] }

export const MESSAGES = 'Messages'

// Catppuccin Mocha. Each category keeps one color; tools take the palette's,
// none of them a category's, in the order they were first used.
const CATEGORIES: Record<string, { label: string; color: string }> = {
  'System prompt': { label: 'system prompt', color: '#7f849c' },
  'System tools': { label: 'system tools', color: '#9399b2' },
  'MCP tools': { label: 'mcp tools', color: '#74c7ec' },
  'MCP server instructions': { label: 'mcp instructions', color: '#94e2d5' },
  'Custom agents': { label: 'agents', color: '#f5c2e7' },
  'Memory files': { label: 'memory', color: '#fab387' },
  'Skills': { label: 'skills', color: '#f9e2af' },
  [MESSAGES]: { label: 'messages', color: '#cba6f7' },
}
const PALETTE = ['#89b4fa', '#a6e3a1', '#f38ba8', '#b4befe', '#89dceb', '#eba0ac', '#f2cdcd', '#f5e0dc']
const OTHER_COLOR = '#6c7086'
const TEXT_COLOR = '#a6adc8'
const ROOM_COLOR = '#585b70'

const FILL = { solid: '█', mcp: '╲', free: '·', buffer: '░' }

// What an image or a document costs, roughly; its base64 would count many
// times that.
const MEDIA_CHARS = 1600 * 4

const ROW_LABEL = 9

type Block = { type: string; [field: string]: unknown }
type Message = { content: readonly Block[] }
type Breakdown = { rawMaxTokens: number; categories: readonly Pick<ContextCategory, 'name' | 'tokens' | 'kind'>[] }

export function isEmpty(snapshot: Snapshot): boolean {
  return snapshot.window <= 0
}

function sum(parts: readonly { tokens: number }[]): number {
  return parts.reduce((n, part) => n + part.tokens, 0)
}

function chars(value: unknown): number {
  if (value === undefined) return 0
  if (typeof value === 'string') return value.length
  if (Array.isArray(value)) return value.reduce<number>((n, part) => n + chars(part), 0)
  if (typeof value === 'object' && value !== null) {
    const block = value as Block
    if (block.type === 'text') return chars(block.text)
    if (block.type === 'image' || block.type === 'document') return MEDIA_CHARS
  }
  return JSON.stringify(value).length
}

// Each tool's calls and results in the window, as /context splits Messages: a
// call by its name and input, a result by its content, roughly 4 characters
// per token. A result whose call is gone is left to the text.
export function toolParts(messages: readonly Message[]): Part[] {
  const names = new Map<string, string>()
  const sizes = new Map<string, number>()
  const add = (name: string, n: number) => sizes.set(name, (sizes.get(name) ?? 0) + n)
  for (const { content } of messages) {
    for (const block of content) {
      if (block.type === 'tool_use' && typeof block.name === 'string') {
        if (typeof block.id === 'string') names.set(block.id, block.name)
        add(block.name, block.name.length + JSON.stringify(block.input ?? {}).length)
      } else if (block.type === 'tool_result' && typeof block.tool_use_id === 'string') {
        const name = names.get(block.tool_use_id)
        if (name !== undefined) add(name, chars(block.content))
      }
    }
  }
  return [...sizes].map(([name, n]) => ({ name, tokens: Math.ceil(n / 4) }))
}

export function toSnapshot(breakdown: Breakdown, messages: readonly Message[]): Snapshot {
  return {
    window: breakdown.rawMaxTokens,
    categories: breakdown.categories
      .filter(category => category.kind === 'used' && category.tokens > 0)
      .map(({ name, tokens }) => ({ name, tokens })),
    buffer: sum(breakdown.categories.filter(category => category.kind === 'buffer')),
    tools: toolParts(messages),
  }
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

function bySize(a: Item, b: Item): number {
  return b.tokens - a.tokens
}

function categoryItem(part: Part): Item {
  const known = CATEGORIES[part.name]
  return {
    key: `category:${part.name}`,
    label: known?.label ?? part.name.toLowerCase(),
    tokens: part.tokens,
    kind: 'category',
    isEstimate: false,
    color: known?.color ?? OTHER_COLOR,
    fill: FILL.solid,
  }
}

function roomItem(label: 'free' | 'buffer', tokens: number): Item {
  return { key: label, label, tokens, kind: 'room', isEstimate: false, color: ROOM_COLOR, fill: FILL[label] }
}

// The context row: the categories in the engine's order, then the free space
// and the compaction buffer, so the row spans the whole window.
export function contextItems(snapshot: Snapshot): Item[] {
  const used = snapshot.categories.map(categoryItem)
  const free = Math.max(0, snapshot.window - sum(used) - snapshot.buffer)
  return [...used, roomItem('free', free), roomItem('buffer', snapshot.buffer)].filter(item => item.tokens > 0)
}

export function toolItems(tools: readonly Part[]): Item[] {
  const mcpNames = new Map<string, number>()
  for (const { name } of tools) {
    const mcp = mcpParts(name)
    if (mcp) mcpNames.set(mcp.name, (mcpNames.get(mcp.name) ?? 0) + 1)
  }
  return tools.map(({ name, tokens }, index): Item => {
    const mcp = mcpParts(name)
    const label = mcp === null ? name
      : (mcpNames.get(mcp.name) ?? 0) > 1 ? `${mcp.server}.${mcp.name}` : mcp.name
    return {
      key: `tool:${name}`,
      label,
      tokens,
      kind: mcp === null ? 'tool' : 'mcp',
      isEstimate: true,
      color: PALETTE[index % PALETTE.length] ?? OTHER_COLOR,
      fill: mcp === null ? FILL.solid : FILL.mcp,
    }
  }).sort(bySize)
}

function messagesTotal(snapshot: Snapshot): number {
  return snapshot.categories.find(category => category.name === MESSAGES)?.tokens ?? 0
}

// The messages row: each tool's share, then the text around them. The
// engine's Messages total is the real figure, so tool estimates past it scale
// down to fit.
export function messageItems(snapshot: Snapshot): Item[] {
  const total = messagesTotal(snapshot)
  const tools = toolItems(snapshot.tools)
  const estimated = sum(tools)
  const scale = estimated > total ? total / estimated : 1
  const shares = tools
    .map(item => ({ ...item, tokens: Math.floor(item.tokens * scale) }))
    .filter(item => item.tokens > 0)
  const text = total - sum(shares)
  if (text <= 0) return shares
  return [...shares, { key: 'text', label: 'text', tokens: text, kind: 'text', isEstimate: true, color: TEXT_COLOR, fill: FILL.solid }]
}

function merge(items: Item[], fill: string): Item {
  return {
    key: 'other',
    label: 'other',
    tokens: sum(items),
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
  const total = sum(all)
  const spare = width - all.length
  const shares = all.map(item => (total > 0 ? (item.tokens / total) * spare : 0))
  const cells = shares.map(share => 1 + Math.floor(share))
  let left = width - cells.reduce((n, c) => n + c, 0)
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
    list.reduce((n, item) => n + legendText(item).length, 0) + LEGEND_GAP * Math.max(0, list.length - 1)
  for (let count = named.length; count >= 0; count -= 1) {
    const rest = [...named.slice(count), ...others]
    const list = rest.length > 0 ? [...named.slice(0, count), merge(rest, FILL.solid)] : named
    if (sizeOf(list) <= width) return list
  }
  return []
}

function percent(tokens: number, window: number): number {
  return window > 0 ? Math.round((tokens / window) * 100) : 0
}

// Plain data for the band: the context row, the messages row when there are
// messages, then the legend when a row is left for it. The legend leaves out
// the free space, the buffer, and Messages, which its own row splits.
export function draw(snapshot: Snapshot, columns: number, maxRows: number): View {
  const kinds = [
    { name: 'context', items: contextItems(snapshot), total: `${percent(sum(snapshot.categories), snapshot.window)}%` },
    { name: 'messages', items: messageItems(snapshot), total: compact(messagesTotal(snapshot)) },
  ].filter(kind => kind.items.length > 0)
  const totalWidth = Math.max(0, ...kinds.map(kind => kind.total.length))
  const barWidth = columns - ROW_LABEL - 1 - totalWidth
  const rows = kinds.slice(0, Math.max(0, maxRows)).map(kind => ({
    name: kind.name.padEnd(ROW_LABEL),
    total: kind.total.padStart(totalWidth),
    segments: layout(kind.items, barWidth, FILL.solid),
  }))
  const entries = rows
    .flatMap(row => row.segments)
    .filter(item => item.kind !== 'room' && item.key !== `category:${MESSAGES}`)
  const legend = rows.length < maxRows ? fitLegend(entries, columns) : []
  return { rows, legend }
}
