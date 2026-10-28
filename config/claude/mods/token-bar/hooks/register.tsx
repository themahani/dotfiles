import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, Timer } from 'claude-code'

import { EMPTY, LEGEND_GAP, draw, isEmpty, legendText, toSnapshot } from './bar'

const snapshot = atom({ plugin: 'token-bar', key: 'snapshot' } as const, EMPTY)
const isHidden = atom({ plugin: 'token-bar', key: 'isHidden' } as const, false)

// How long the main loop must go quiet before a recount, so a burst of model
// requests is counted once.
export const SETTLE_MS = 250

// The per-call tallies saved before the band measured the context.
const OLD_TALLY = 'tally:'

let timer: Timer | undefined
let isCounting = false
let isStale = false

// Hooks only set a timer, so no turn waits on a count.
function schedule($: EngineInterface): void {
  timer?.cancel()
  // A failed count leaves the last snapshot; the next turn counts again.
  timer = $.clock.after(SETTLE_MS, () => {
    recount($).catch(() => undefined)
  })
}

// One count at a time: a timer that fires during one runs it once more after.
async function recount($: EngineInterface): Promise<void> {
  timer = undefined
  if (isCounting) {
    isStale = true
    return
  }
  isCounting = true
  try {
    do {
      isStale = false
      await measure($)
    } while (isStale)
  } finally {
    isCounting = false
  }
}

// `summary` estimates locally and sends no token-count requests.
async function measure($: EngineInterface): Promise<void> {
  if (await read($, isHidden)) return
  const [usage, messages] = await Promise.all([
    $.session.usage({ breakdown: 'summary' }),
    $.session.messages({ as: 'api' }),
  ])
  const breakdown = usage.context.breakdown
  if (breakdown === undefined || !Array.isArray(messages)) return
  await update($, snapshot, () => toSnapshot(breakdown, messages))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'token-bar',
      description: 'Show or hide the context bar above the prompt',
    })
    const hidden = (await $.store.get('hidden')) === true
    await update($, isHidden, () => hidden)
    for (const key of await $.store.keys()) {
      if (key.startsWith(OLD_TALLY)) await $.store.delete(key)
    }

    // A resumed session has a context to show before its first turn.
    schedule($)

    return next(e)
  })

  on('session.end', async ($, e, next) => {
    if (e.reason === 'clear') {
      timer?.cancel()
      await update($, snapshot, () => EMPTY)
    }

    return next(e)
  })

  on('command.run', { command: 'token-bar' }, async $ => {
    const hidden = await update($, isHidden, value => !value)
    await $.store.set('hidden', hidden)
    if (!hidden) schedule($)

    return { text: hidden ? 'Token bar hidden.' : 'Token bar shown.' }
  })

  // A subagent's requests fill its own window, not this one.
  on('turn.step', async function* ($, e, next) {
    const step = yield* next(e)
    if (e.agentId === undefined) schedule($)

    return step
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.agentId === undefined) schedule($)

    return done
  }).catch(($, e, next) => next(e))

  on('session.compact', async ($, e, next) => {
    const compacted = await next(e)
    if (e.agentId === undefined) schedule($)

    return compacted
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const value = await read($, snapshot)
    if (e.props.hasSurvey || isEmpty(value) || (await read($, isHidden))) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const view = draw(value, e.props.bodyColumns, e.props.maxRows)

    return (
      <Box flexDirection="column">
        {view.rows.map(row => (
          <Box key={row.name.trim()}>
            <Text dimColor>{row.name}</Text>
            {row.segments.map(segment => (
              <Text color={segment.color}>{segment.fill.repeat(segment.cells)}</Text>
            ))}
            <Text dimColor> {row.total}</Text>
          </Box>
        ))}
        {view.legend.length > 0 && (
          <Box key="legend" columnGap={LEGEND_GAP}>
            {view.legend.map(item => (
              <Box key={item.key}>
                <Text color={item.color}>{item.fill}</Text>
                <Text dimColor>{legendText(item).slice(item.fill.length)}</Text>
              </Box>
            ))}
          </Box>
        )}
      </Box>
    )
  })
}
