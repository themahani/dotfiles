import { describe, expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'

import {
  EMPTY, addAgent, addTool, compact, draw, estimate, layout, nameAgent, settleAgent, toolItems,
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

const SPAWNER = { plugin: 'core', tier: 'core' } as const

const TOGGLE = {
  command: 'token-bar',
  args: '',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: false, columns: 80 },
} as const

const USAGE = {
  model: 'test-model',
  input_tokens: 1000,
  output_tokens: 200,
  cache_read_input_tokens: 3000,
  cache_creation_input_tokens: 800,
}

// The hooks here stand for the engine beneath the plugin.
function engine(on: On) {
  mock.store(on)
  on('session.id', () => ({ value: 'S1' }))
  on('command.register', () => ({ value: { command: 'token-bar' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.end', (_, e) => ({ sessionId: e.sessionId }))
  on('turn.complete', () => ({ text: '' }))
  on('agent.spawn', () => ({ model: 'test-model', agentId: 'a1' }))
  on('tool.call', (_, e) =>
    e.tool === 'Agent'
      ? { result: { status: 'completed', agentId: 'a1', agentType: 'Explore', totalTokens: 9000 }, text: 'report' }
      : { result: {}, text: 'x'.repeat(400) })
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
}

async function start($: Engine) {
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
}

describe('bar', () => {
  test('estimates tokens from the arguments and the result, not the envelope', () => {
    const input = { tool: 'Bash', tool_use_id: 't1', agentId: 'a1', command: 'ls' }
    // {"command":"ls"} is 16 characters, the result 400.
    expect(estimate(input, 'x'.repeat(400))).toBe(104)
  })

  test('formats counts compactly', () => {
    expect(compact(950)).toBe('950')
    expect(compact(9100)).toBe('9.1k')
    expect(compact(135_000)).toBe('135k')
    expect(compact(1_200_000)).toBe('1.2M')
  })

  test('fills the width and gives every segment a cell', () => {
    let tally = addTool(EMPTY, 'Bash', 10_000)
    tally = addTool(tally, 'Read', 10)
    const segments = layout(toolItems(tally), 20, '█')
    expect(segments.map(s => s.cells).reduce((a, b) => a + b, 0)).toBe(20)
    expect(segments.find(s => s.label === 'Read')?.cells).toBe(1)
  })

  test('merges what does not fit into other', () => {
    let tally = EMPTY
    for (const tool of ['A', 'B', 'C', 'D', 'E']) tally = addTool(tally, tool, 100)
    const segments = layout(toolItems(tally), 3, '█')
    expect(segments.map(s => s.label)).toEqual(['A', 'B', 'other'])
    expect(segments[2]?.tokens).toBe(300)
  })

  test('names an MCP tool by its tool name, and by server too when two share it', () => {
    let tally = addTool(EMPTY, 'mcp__docs__batch', 10)
    expect(toolItems(tally)[0]?.label).toBe('batch')
    expect(toolItems(tally)[0]?.fill).toBe('╲')
    tally = addTool(tally, 'mcp__notes__batch', 5)
    expect(toolItems(tally).map(item => item.label)).toEqual(['docs.batch', 'notes.batch'])
  })

  test('groups agents by type and keeps the larger final figure', () => {
    let tally = nameAgent(EMPTY, 'a1', 'Explore')
    tally = addAgent(tally, 'a1', 500)
    tally = addAgent(nameAgent(tally, 'a2', 'Explore'), 'a2', 300)
    tally = settleAgent(tally, 'a1', 400)
    const view = draw(tally, 60, 3)
    expect(view.rows.map(row => row.name.trim())).toEqual(['agents'])
    expect(view.legend.map(item => [item.label, item.tokens])).toEqual([['Explore', 800]])
  })

  test('drops the legend when only the bars fit', () => {
    const tally = addAgent(nameAgent(addTool(EMPTY, 'Bash', 10), 'a1', 'Plan'), 'a1', 10)
    expect(draw(tally, 60, 2).legend).toEqual([])
    expect(draw(tally, 60, 3).legend.length).toBe(2)
  })
})

describe('band', () => {
  test('shows main-loop tool calls and skips a subagent\'s', async ($, on) => {
    engine(on)
    await start($)
    await $.tool.call({ tool: 'Bash', command: 'ls' })
    await $.tool.call({ tool: 'Read', file_path: '/x', agentId: 'a9' })

    for (const surface of ['terminal', 'desktop'] as const) {
      const ui = await $.ui.mount({ ...BAND, surface })
      expect(await ui.find({ type: 'Text', text: /Bash ~104/ })).toBeDefined()
      expect(await ui.find({ type: 'Text', text: /Read/ })).toBeUndefined()
      await ui.unmount()
    }
  })

  test('gives an MCP tool the hatched fill', async ($, on) => {
    engine(on)
    await start($)
    await $.tool.call({ tool: 'mcp__srv__batch', query: 'q' })

    const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: /batch ~/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /^╲+$/ })).toBeDefined()
    await ui.unmount()
  })

  test('counts a subagent by type and settles it to its final figure', async ($, on) => {
    engine(on)
    await start($)
    await $.agent.spawn({
      tool_use_id: 't1', prompt: 'p', description: 'd', subagentType: 'Explore',
      provider: SPAWNER, parentModel: 'test-model', background: false, fork: false,
    })
    await $.turn.complete({
      answer: '', durationMs: 1, isAborted: false, turnId: 'turn1', agentId: 'a1',
      usage: USAGE, reason: 'answer',
    })

    let ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: /Explore 5\.0k/ })).toBeDefined()
    await ui.unmount()

    await $.tool.call({ tool: 'Agent', description: 'd', prompt: 'p', subagent_type: 'Explore' })
    ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: /Explore 9\.0k/ })).toBeDefined()
    // The Agent call itself is not a tool segment.
    expect(await ui.find({ type: 'Text', text: /Agent ~/ })).toBeUndefined()
    await ui.unmount()
  })

  test('grows a running subagent with each of its model requests', async ($, on) => {
    engine(on)
    on('turn.step', async function* (_, e) {
      return {
        turnId: e.turnId, index: e.index, answer: '', toolUses: [], stopReason: 'tool_use' as const, usage: USAGE,
      }
    })
    await start($)
    await $.agent.spawn({
      tool_use_id: 't1', prompt: 'p', description: 'd', subagentType: 'Plan',
      provider: SPAWNER, parentModel: 'test-model', background: true, fork: false,
    })
    for (const index of [0, 1]) {
      const step = $.turn.step({ turnId: 'turn1', index, model: 'test-model', messageCount: 1, agentId: 'a1' })
      for await (const _ of step) { /* read to the end */ }
      await step.result
    }
    // A main-loop request is not an agent's.
    const main = $.turn.step({ turnId: 'turn0', index: 0, model: 'test-model', messageCount: 1 })
    for await (const _ of main) { /* read to the end */ }

    const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: /Plan 10\.0k/ })).toBeDefined()
    await ui.unmount()
  })

  test('/token-bar hides the band and shows it again', async ($, on) => {
    engine(on)
    await start($)
    await $.tool.call({ tool: 'Bash', command: 'ls' })

    expect((await $.command.run(TOGGLE)).text).toBe('Token bar hidden.')
    let ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: 'engine' })).toBeDefined()
    await ui.unmount()

    expect((await $.command.run(TOGGLE)).text).toBe('Token bar shown.')
    ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: /Bash/ })).toBeDefined()
    await ui.unmount()
  })

  test('/clear resets the tally', async ($, on) => {
    engine(on)
    await start($)
    await $.tool.call({ tool: 'Bash', command: 'ls' })
    await $.session.end({ reason: 'clear', sessionId: 'S1', resume: { id: 'S1' } })

    const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
    expect(await ui.find({ type: 'Text', text: 'engine' })).toBeDefined()
    await ui.unmount()
  })
})
