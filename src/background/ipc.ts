import {
  breakIndex,
  lastSchedulerJobDate,
  lastSchedulerJobLength,
} from './store'
import { ipcMain, ipcRenderer } from 'electron-better-ipc'
import { setNewBreak, NewBreakOptions } from './breaker'
import { app } from 'electron'
export const channelSetBreak = 'set-break'
export const channelGetBreakCount = 'break-count'
export const channelCloseApp = 'close-app'
export const channelGetBreakerData = 'breaker-data'

export interface OptionsSetBreak {
  forceNextBreakIn: number
}

//? ipc for renderer
export const rendererGetBreakIndex = async (): Promise<number> => {
  return await ipcRenderer.callMain(channelGetBreakCount)
}

export const rendererGetBreakerData = async (): Promise<{
  lastSchedulerJobDate: typeof lastSchedulerJobDate.value
  lastSchedulerJobLength: typeof lastSchedulerJobLength.value
}> => {
  return await ipcRenderer.callMain(channelGetBreakerData)
}

export const rendererSetNextBreak = async (
  options: NewBreakOptions
): Promise<void> => {
  return await ipcRenderer.callMain(channelSetBreak, options)
}

export const rendererCloseApp = async (): Promise<true> => {
  return await ipcRenderer.callMain(channelCloseApp)
}

//? ipc for main
export const useIpcMain = () => {
  ipcMain.answerRenderer(channelGetBreakCount, () => {
    return breakIndex.value
  })

  ipcMain.answerRenderer(channelGetBreakerData, () => {
    return {
      lastSchedulerJobDate: lastSchedulerJobDate.value,
      lastSchedulerJobLength: lastSchedulerJobLength.value,
    }
  })

  ipcMain.answerRenderer(channelSetBreak, (options: NewBreakOptions) => {
    setNewBreak(options)
    return true
  })

  ipcMain.answerRenderer(channelCloseApp, () => {
    app.quit()
    return true
  })
}
