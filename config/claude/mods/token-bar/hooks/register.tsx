import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Tally } from '../types'
import {
  EMPTY, LEGEND_GAP, addAgent, addTool, draw, estimate, isEmpty, isTally,
  legendText, nameAgent, settleAgent,
} from './bar'

const tally = atom({ plugin: 'token-bar', key: 'tally' } as const, EMPTY)
const isHidden = atom({ plugin: 'token-bar', key: 'isHidden' } as const, false)

// Saved tallies kept for resuming; older sessions' are dropped.
const KEEP_SESSIONS = 20
const SAVED = 'tally:'

async function change($: EngineInterface, fn: (value: Tally) => Tally): Promise<void> {
  const value = await update($, tally, fn)
  await $.store.set(SAVED + (await $.session.id()), value)
}

async function prune($: EngineInterface, current: string): Promise<void> {
  const saved = (await $.store.keys()).filter(key => key.startsWith(SAVED) && key !== current)
  for (const key of saved.slice(0, Math.max(0, saved.length - (KEEP_SESSIONS - 1)))) {
    await $.store.delete(key)
  }
}

function usageSum(usage: { input_tokens: number; output_tokens: number; cache_read_input_tokens: number; cache_creation_input_tokens: number }): number {
  return usage.input_tokens + usage.output_tokens + usage.cache_read_input_tokens + usage.cache_creation_input_tokens
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'token-bar',
      description: 'Show or hide the token bar above the prompt',
    })
    const hidden = (await $.store.get('hidden')) === true
    await update($, isHidden, () => hidden)

    // A reload keeps the atom; a resumed session starts from what it saved.
    const key = SAVED + (await $.session.id())
    const saved = await $.store.get(key)
    if (isTally(saved)) {
      await update($, tally, value => (isEmpty(value) ? saved : value))
    }
    await prune($, key)

    return next(e)
  })

  on('session.end', async ($, e, next) => {
    if (e.reason === 'clear') {
      await update($, tally, () => EMPTY)
    }

    return next(e)
  })

  on('command.run', { command: 'token-bar' }, async $ => {
    const hidden = await update($, isHidden, value => !value)
    await $.store.set('hidden', hidden)

    return { text: hidden ? 'Token bar hidden.' : 'Token bar shown.' }
  })

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    // A subagent's own calls are part of that agent's spend.
    if (e.agentId !== undefined) return ran

    if (e.tool === 'Agent') {
      if (ran.deny === undefined && ran.isError !== true) {
        const result: unknown = ran.result
        const record = (typeof result === 'object' && result !== null ? result : {}) as {
          agentId?: unknown; agentType?: unknown; status?: unknown; totalTokens?: unknown
        }
        if (typeof record.agentId === 'string') {
          const agentId = record.agentId
          const type = typeof record.agentType === 'string' ? record.agentType : e.subagent_type ?? 'general-purpose'
          await change($, value => {
            const named = nameAgent(value, agentId, type)
            return record.status === 'completed' && typeof record.totalTokens === 'number'
              ? settleAgent(named, agentId, record.totalTokens)
              : named
          })
        }
      }
      return ran
    }

    const tokens = estimate(e, ran.deny === undefined ? ran.text : undefined)
    await change($, value => addTool(value, e.tool, tokens))

    return ran
  }).catch(($, e, next) => next(e))

  on('agent.spawn', async ($, e, next) => {
    const spawned = await next(e)
    const agentId = spawned.deny === undefined ? spawned.agentId : undefined
    if (agentId !== undefined) {
      await change($, value => nameAgent(value, agentId, e.subagentType))
    }

    return spawned
  }).catch(($, e, next) => next(e))

  // A subagent's run is one turn, so its steps are what grow it live.
  on('turn.step', async function* ($, e, next) {
    const step = yield* next(e)
    const agentId = e.agentId
    if (agentId !== undefined && step.usage) {
      const tokens = usageSum(step.usage)
      await change($, value => addAgent(value, agentId, tokens))
    }

    return step
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    const agentId = e.agentId
    if (agentId !== undefined && e.usage) {
      const tokens = usageSum(e.usage)
      await change($, value => settleAgent(value, agentId, tokens))
    }

    return done
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const value = await read($, tally)
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
