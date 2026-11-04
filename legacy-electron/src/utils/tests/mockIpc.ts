import { formatISO, addMinutes } from 'date-fns'
import { GetBreakDataAnswer } from '@/background/ipc'
import { NewBreakOptions } from '@/background/breaker'
export type ChannelID =
  | 'rendererGetBreakData'
  | 'rendererSetNextBreak'
  | 'rendererCloseApp'
export const mockFnChannel = jest.fn(
  <O extends {}>(id: ChannelID, options: O) => {}
)
export const mockDateIso = formatISO(addMinutes(new Date(), 15))

const mockCreateChannel = <O extends {}, A extends {}>(
  id: ChannelID,
  answer: A
) => ({
  ask: async (options: O) =>
    new Promise((resolve) => {
      mockFnChannel(id, options)
      resolve(answer)
    }),
})

export const mockIpc = {
  rendererGetBreakData: mockCreateChannel<{}, GetBreakDataAnswer>(
    'rendererGetBreakData',
    {
      breakIndex: 2,
      lastSchedulerJobDate: mockDateIso,
      lastSchedulerJobLength: 5 * 60,
    }
  ),
  rendererSetNextBreak: mockCreateChannel<NewBreakOptions, {}>(
    'rendererSetNextBreak',
    {}
  ),
  rendererCloseApp: mockCreateChannel<{}, {}>('rendererCloseApp', {}),
}
