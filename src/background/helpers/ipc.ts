import { breakIndex } from './store'
import { ipcMain } from 'electron-better-ipc'
import { setNewBreak } from './breaker'

export const channelSetBreak = 'set-break'
export const channelGetBreakCount = 'break-count'

export const useIpcMain = () => {
  ipcMain.answerRenderer(channelGetBreakCount, () => {
    return breakIndex.value
  })

  ipcMain.answerRenderer(channelSetBreak, (options) => {
    let forceNextBreakIn
    if (options) {
      forceNextBreakIn = options.forceNextBreakIn
    }

    setNewBreak(forceNextBreakIn)
    return true
  })
}
