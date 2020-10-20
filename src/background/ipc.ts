import { expectCall } from '@/utils/tests/electron'

import {
  breakIndex,
  lastSchedulerJobDate,
  lastSchedulerJobLength,
} from './store'
import {
  createWindowIndexChildren,
  focusOn,
  setBackgroundOf,
  rendererWindows,
} from './windows'
import { setNewBreak, NewBreakOptions } from './breaker'
import { isProdBuild } from './env'
import { app, ipcMain, ipcRenderer } from 'electron'
// export const channelSetBreak = 'set-break'
// export const channelGetBreakCount = 'break-count'
// export const channelCloseApp = 'close-app'
// export const channelGetBreakerData = 'breaker-data'

class IpcChanel<
  RendererAskPayload extends {},
  RendererAskAnswer extends {} | undefined
> {
  private readonly mainChanelId: string
  private readonly rendererChanelId: string
  constructor(baseChanelId: string, private readonly respondToAll: boolean) {
    this.mainChanelId = `${baseChanelId}-main`
    this.rendererChanelId = `${baseChanelId}-renderer`
  }

  readonly renderer = {
    ask: async (options: RendererAskPayload): Promise<RendererAskAnswer> =>
      new Promise((resolve, reject) => {
        const called = expectCall(
          `IPC chanel expect answer from [mainId: ${this.mainChanelId}] to [rendererId: ${this.rendererChanelId}]`
        )
        ipcRenderer.on(
          this.mainChanelId,
          (_event, answer: RendererAskAnswer) => {
            if (called) called()
            resolve(answer)
          }
        )
        if (!isProdBuild) {
          setTimeout(() => {
            reject(`timeout while waiting for ${this.mainChanelId} to response`)
          }, 3000)
        }
        ipcRenderer.send(this.rendererChanelId, options)
      }),
    listen: async (): Promise<RendererAskAnswer> =>
      new Promise((resolve) => {
        ipcRenderer.on(
          this.mainChanelId,
          (_event, answer: RendererAskAnswer) => {
            resolve(answer)
          }
        )
      }),
  }

  readonly main = {
    listen: (
      answerHandler: (payload: RendererAskPayload) => RendererAskAnswer
    ) => {
      ipcMain.on(
        this.rendererChanelId,
        (event, payload: RendererAskPayload) => {
          try {
            if (this.respondToAll) {
              const windowsEntries = Object.entries(rendererWindows)
              windowsEntries.forEach(([_key, win]) => {
                if (win) {
                  win.webContents.send(this.mainChanelId, answerHandler(payload))
                }
              })
            } else {
              const answer = answerHandler(payload)
              if (answer) event.reply(this.mainChanelId, answer)
            }
          } catch (error) {
            console.error(error)
          }
        }
      )
    },
  }
}

class IpcChanelFactory {
  private static index = 0
  private static generateId() {
    this.index++
    return `auto-generated-${this.index}`
  }
  static create<
    RendererAskPayload extends {},
    RendererAskAnswer extends {} | undefined
  >(respondToAll = false) {
    const id = this.generateId()
    return new IpcChanel<RendererAskPayload, RendererAskAnswer>(
      id,
      respondToAll
    )
  }
}

//? ipc for renderer
export interface GetBreakDataAnswer {
  breakIndex: number
  lastSchedulerJobDate: typeof lastSchedulerJobDate.value
  lastSchedulerJobLength: typeof lastSchedulerJobLength.value
}
export const {
  main: mainGetBreakData,
  renderer: rendererGetBreakData,
} = IpcChanelFactory.create<{}, GetBreakDataAnswer>()

export const {
  main: mainSetNextBreak,
  renderer: rendererSetNextBreak,
} = IpcChanelFactory.create<NewBreakOptions, {}>()

export const {
  main: mainCloseApp,
  renderer: rendererCloseApp,
} = IpcChanelFactory.create<{}, undefined>()

export const {
  main: mainStartBreak,
  renderer: rendererStartBreak,
} = IpcChanelFactory.create<{}, {}>()

export const {
  main: mainEmitLanguage,
  renderer: rendererEmitLanguage,
} = IpcChanelFactory.create<{ lang: string }, { lang: string }>(true)

export const {
  main: mainEmitEndBreak,
  renderer: rendererEmitEndBreak,
} = IpcChanelFactory.create<{}, {}>(true)

//? ipc for main
export const useIpcMain = () => {
  mainGetBreakData.listen(() => ({
    breakIndex: breakIndex.value,
    lastSchedulerJobDate: lastSchedulerJobDate.value,
    lastSchedulerJobLength: lastSchedulerJobLength.value,
  }))

  mainSetNextBreak.listen(async (options) => {
    try {
      await setNewBreak(options)
    } catch (error) {
      console.error(error)
    }
    return {}
  })

  mainCloseApp.listen(() => {
    app.quit()
    return undefined
  })

  mainStartBreak.listen(async () => {
    const indexKey = 'windowIndex'
    setBackgroundOf(indexKey)
    focusOn(indexKey)
    try {
      await createWindowIndexChildren()
    } catch (error) {
      console.error(error)
    }
    return {}
  })

  mainEmitLanguage.listen(({ lang }) => ({ lang }))
  mainEmitEndBreak.listen(() => ({}))
}
