import { describe, expect, mock, test } from 'claude-code/testing'
import type { On, SessionContextBreakdown } from 'claude-code'
import type { Engine } from 'claude-code/testing'

import { SETTLE_MS } from './register'
import {
  EMPTY, compact, contextItems, draw, layout, messageItems, toSnapshot, toolItems, toolParts,
} from './bar'

const BAND = {
  plugin: 'token-bar',
  component: 'AbovePrompt',
  props: {
    hasSurvey: false,
    isWorking: false,
    maxRows: 3,
    bodyColumns: 80,
    scroll: { offset: 0, bodyRows: 3 },
    view: {},
  },
} as const

const TOGGLE = {
  command: 'token-bar',
  args: '',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: false, columns: 80 },
} as const

function category(name: string, tokens: number, kind: 'used' | 'free' | 'buffer' | 'deferred') {
  return { name, tokens, color: 'inactive', isDeferred: kind === 'deferred', kind }
}

const BREAKDOWN: SessionContextBreakdown = {
  categories: [
    category('System prompt', 3000, 'used'),
    category('System tools', 12_000, 'used'),
    category('MCP tools (deferred)', 5000, 'deferred'),
    category('Messages', 20_000, 'used'),
    category('Free space', 132_000, 'free'),
    category('Autocompact buffer', 33_000, 'buffer'),
  ],
  totalTokens: 35_000,
  maxTokens: 200_000,
  rawMaxTokens: 200_000,
  autocompactSource: 'model-default',
  percentage: 18,
  gridRows: [],
  model: 'test-model',
  memoryFiles: [],
  mcpTools: [],
  agents: [],
  isAutoCompactEnabled: true,
  apiUsage: null,
}

// Bash's call is 4 + 16 characters and its result 400: 105 tokens.
const MESSAGES = [
  { role: 'user', content: [{ type: 'text', text: 'hi' }] },
  { role: 'assistant', content: [{ type: 'tool_use', id: 't1', name: 'Bash', input: { command: 'ls' } }] },
  { role: 'user', content: [{ type: 'tool_result', tool_use_id: 't1', content: 'x'.repeat(400) }] },
] as const

const USAGE = {
  model: 'test-model',
  input_tokens: 1000,
  output_tokens: 200,
  cache_read_input_tokens: 3000,
  cache_creation_input_tokens: 800,
}

// The hooks here stand for the engine beneath the plugin; `counts` is how
// many times the plugin asked for a breakdown, `store` what it keeps.
function engine(on: On, stored: Record<string, unknown> = {}) {
  const counts = { usage: 0 }
  const store = new Map(Object.entries(stored))
  const clock = mock.clock(on)
  on('store.get', (_, e) => ({ value: store.get(e.key) }))
  on('store.set', (_, e) => ({ value: void store.set(e.key, e.value) }))
  on('store.delete', (_, e) => ({ value: void store.delete(e.key) }))
  on('store.keys', () => ({ value: [...store.keys()] }))
  on('session.id', () => ({ value: 'S1' }))
  on('command.register', () => ({ value: { command: 'token-bar' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.end', (_, e) => ({ sessionId: e.sessionId }))
  on('session.compact', (_, e) => ({ messages: e.messages }))
  on('turn.complete', () => ({ text: '' }))
  on('turn.step', async function* (_, e) {
    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [], stopReason: 'end_turn' as const, usage: USAGE }
  })
  on('session.usage', () => {
    counts.usage += 1
    return { value: { startedAt: 0, context: { window: 200_000, breakdown: BREAKDOWN }, rateLimits: [] } }
  })
  on('session.messages', () => ({ value: MESSAGES.map(m => ({ role: m.role, content: [...m.content] })) }))
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  return { counts, clock, store }
}

async function start($: Engine) {
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
}

async function step($: Engine, agentId?: string) {
  const run = $.turn.step({ turnId: 'turn1', index: 0, model: 'test-model', messageCount: 1, agentId })
  for await (const _ of run) { /* read to the end */ }
  await run.result
}

describe('bar', () => {
  test('splits a tool\'s calls and results by name, in first-use order', () => {
    const parts = toolParts([
      { content: [
        { type: 'tool_use', id: 'a', name: 'Read', input: { file_path: '/x' } },
        { type: 'tool_use', id: 'b', name: 'Agent', input: {} },
      ] },
      { content: [
        { type: 'tool_result', tool_use_id: 'a', content: [{ type: 'image', source: { data: 'z'.repeat(100_000) } }] },
        { type: 'tool_result', tool_use_id: 'b', content: [{ type: 'text', text: 'y'.repeat(398) }] },
        // A result whose call was compacted away is text.
        { type: 'tool_result', tool_use_id: 'gone', content: 'w'.repeat(4000) },
      ] },
    ])
    // Read: 4 + 17 characters and an image at 1600 tokens; Agent: 5 + 2 + 398.
    expect(parts).toEqual([{ name: 'Read', tokens: 1606 }, { name: 'Agent', tokens: 102 }])
  })

  test('keeps the categories in the window and the compaction buffer', () => {
    const snapshot = toSnapshot(BREAKDOWN, [])
    expect(snapshot.categories.map(c => c.name)).toEqual(['System prompt', 'System tools', 'Messages'])
    expect(snapshot.buffer).toBe(33_000)
    expect(contextItems(snapshot).map(item => [item.label, item.tokens])).toEqual([
      ['system prompt', 3000], ['system tools', 12_000], ['messages', 20_000], ['free', 132_000], ['buffer', 33_000],
    ])
  })

  test('leaves what the tools do not account for to the text', () => {
    const snapshot = { ...toSnapshot(BREAKDOWN, []), tools: [{ name: 'Bash', tokens: 5000 }] }
    expect(messageItems(snapshot).map(item => [item.label, item.tokens])).toEqual([['Bash', 5000], ['text', 15_000]])
  })

  test('scales tool estimates down to the Messages total', () => {
    const tools = [{ name: 'Bash', tokens: 30_000 }, { name: 'Read', tokens: 10_000 }]
    const items = messageItems({ ...toSnapshot(BREAKDOWN, []), tools })
    expect(items.map(item => [item.label, item.tokens])).toEqual([['Bash', 15_000], ['Read', 5000]])
  })

  test('formats counts compactly', () => {
    expect(compact(950)).toBe('950')
    expect(compact(9100)).toBe('9.1k')
    expect(compact(135_000)).toBe('135k')
    expect(compact(1_200_000)).toBe('1.2M')
  })

  test('fills the width and gives every segment a cell', () => {
    const segments = layout(toolItems([{ name: 'Bash', tokens: 10_000 }, { name: 'Read', tokens: 10 }]), 20, '█')
    expect(segments.map(s => s.cells).reduce((a, b) => a + b, 0)).toBe(20)
    expect(segments.find(s => s.label === 'Read')?.cells).toBe(1)
  })

  test('merges what does not fit into other', () => {
    const items = toolItems(['A', 'B', 'C', 'D', 'E'].map(name => ({ name, tokens: 100 })))
    const segments = layout(items, 3, '█')
    expect(segments.map(s => s.label)).toEqual(['A', 'B', 'other'])
    expect(segments[2]?.tokens).toBe(300)
  })

  test('names an MCP tool by its tool name, and by server too when two share it', () => {
    expect(toolItems([{ name: 'mcp__docs__batch', tokens: 10 }])[0]?.label).toBe('batch')
    expect(toolItems([{ name: 'mcp__docs__batch', tokens: 10 }])[0]?.fill).toBe('╲')
    const both = toolItems([{ name: 'mcp__docs__batch', tokens: 10 }, { name: 'mcp__notes__batch', tokens: 5 }])
    expect(both.map(item => item.label)).toEqual(['docs.batch', 'notes.batch'])
  })

  test('leaves the free space, the buffer and Messages out of the legend', () => {
    const view = draw(toSnapshot(BREAKDOWN, MESSAGES), 80, 3)
    expect(view.rows.map(row => [row.name.trim(), row.total.trim()])).toEqual([['context', '18%'], ['messages', '20.0k']])
    expect(view.legend.map(item => item.label)).toEqual(['text', 'system tools', 'system prompt', 'Bash'])
  })

  test('drops the legend when only the bars fit', () => {
    const snapshot = toSnapshot(BREAKDOWN, MESSAGES)
    expect(draw(snapshot, 80, 2).legend).toEqual([])
    expect(draw(snapshot, 80, 1).rows.map(row => row.name.trim())).toEqual(['context'])
  })

  test('draws nothing before the first count', () => {
    expect(draw(EMPTY, 80, 3).rows).toEqual([])
  })
})

describe('band', () => {
  test('counts the context once the session goes quiet', async ($, on) => {
    const { counts, clock } = engine(on)
    await start($)
    await clock.advance(SETTLE_MS)

    for (const surface of ['terminal', 'desktop'] as const) {
      const ui = await $.ui.mount({ ...BAND, surface })
      expect(await ui.find({ type: 'Text', text: /18%$/ })).toBeDefined()
      expect(await ui.find({ type: 'Text', text: /Bash ~105/ })).toBeDefined()
      await ui.unmount()
    }
    expect(counts.usage).toBe(1)
  })

  test('counts a burst of model requests once', async ($, on) => {
    const { counts, clock } = engine(on)
    await start($)
    await clock.advance(SETTLE_MS)
    for (let i = 0; i < 3; i += 1) await step($)
    expect(counts.usage).toBe(1)

    await clock.advance(SETTLE_MS)
    expect(counts.usage).toBe(2)
  })

  test('skips a subagent\'s requests', async ($, on) => {
    const { counts, clock } = engine(on)
    await start($)
    await clock.advance(SETTLE_MS)
    await step($, 'a1')
    await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 'turn1', agentId: 'a1', reason: 'answer' })
    await clock.advance(SETTLE_MS)
    expect(counts.usage).toBe(1)
  })

  test('counts again after a compaction', async ($, on) => {
    const { counts, clock } = engine(on)
    await start($)
    await clock.advance(SETTLE_MS)
    await $.session.compact({ trigger: 'manual', messages: [{ role: 'user', text: 'summary', toolUses: [] }] })
    await clock.advance(SETTLE_MS)
    expect(counts.usage).toBe(2)
  })

  test('/token-bar hides the band and stops counting until shown', async ($, on) => {
    const { counts, clock } = engine(on)
    await start($)
    await clock.advance(SETTLE_MS)

    expect((await $.command.run(TOGGLE)).text).toBe('Token bar hidden.')
    await step($)
    await clock.advance(SETTLE_MS)
    expect(counts.usage).toBe(1)
    let ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: 'engine' })).toBeDefined()
    await ui.unmount()

    expect((await $.command.run(TOGGLE)).text).toBe('Token bar shown.')
    await clock.advance(SETTLE_MS)
    expect(counts.usage).toBe(2)
    ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: /Bash/ })).toBeDefined()
    await ui.unmount()
  })

  test('/clear empties the band', async ($, on) => {
    const { clock } = engine(on)
    await start($)
    await clock.advance(SETTLE_MS)
    await $.session.end({ reason: 'clear', sessionId: 'S1', resume: { id: 'S1' } })

    const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: 'engine' })).toBeDefined()
    await ui.unmount()
  })

  test('removes the tallies the per-call count saved', async ($, on) => {
    const { store } = engine(on, { 'tally:S0': { tools: {}, agents: {}, order: [] }, hidden: false })
    await start($)
    expect([...store.keys()]).toEqual(['hidden'])
  })
})
