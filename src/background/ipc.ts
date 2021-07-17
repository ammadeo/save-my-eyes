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
import { error, verbose } from 'electron-log'

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
      answerHandler: (payload: RendererAskPayload) => Promise<RendererAskAnswer>
    ) => {
      ipcMain.on(
        this.rendererChanelId,
        async (event, payload: RendererAskPayload) => {
          try {
            const answer = await answerHandler(payload)
            if (!isProdBuild)
              verbose(`ipc answer: (${this.mainChanelId})`, answer)

            if (this.respondToAll) {
              const windowsEntries = Object.entries(rendererWindows)
              windowsEntries.forEach(([_key, win]) => {
                if (win) {
                  win.webContents.send(this.mainChanelId, answer)
                }
              })
            } else {
              if (answer) event.reply(this.mainChanelId, answer)
            }
          } catch (err) {
            error(`ipc answer error: (${this.mainChanelId})`, err)
          }
        }
      )
    },
  }
}

class IpcChanelFactory {
  static create<
    RendererAskPayload extends {},
    RendererAskAnswer extends {} | undefined
  >(id: string, respondToAll = false) {
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
} = IpcChanelFactory.create<{}, GetBreakDataAnswer>('get-break-data')

export const {
  main: mainSetNextBreak,
  renderer: rendererSetNextBreak,
} = IpcChanelFactory.create<NewBreakOptions, {}>('set-next-break')

export const {
  main: mainCloseApp,
  renderer: rendererCloseApp,
} = IpcChanelFactory.create<{}, undefined>('close-app')

export const {
  main: mainStartBreak,
  renderer: rendererStartBreak,
} = IpcChanelFactory.create<{}, {}>('start-break')

export const {
  main: mainEmitLanguage,
  renderer: rendererEmitLanguage,
} = IpcChanelFactory.create<{ lang: string }, { lang: string }>(
  'emit-language',
  true
)

export const {
  main: mainEmitEndBreak,
  renderer: rendererEmitEndBreak,
} = IpcChanelFactory.create<{}, {}>('emit-end-break', true)

//? ipc for main
export const useIpcMain = () => {
  mainGetBreakData.listen(async () => ({
    breakIndex: breakIndex.value,
    lastSchedulerJobDate: lastSchedulerJobDate.value,
    lastSchedulerJobLength: lastSchedulerJobLength.value,
  }))

  mainSetNextBreak.listen(async (options) => {
    try {
      await setNewBreak(options)
    } catch (err) {
      error(err)
    }
    return {}
  })

  mainCloseApp.listen(async () => {
    app.quit()
    return undefined
  })
  // TODO FIX ERROR
  mainStartBreak.listen(async () => {
    try {
      const indexKey = 'windowIndex'
      setBackgroundOf(indexKey)
      focusOn(indexKey)
      await createWindowIndexChildren()
    } catch (err) {
      error(err)
    }
    return {}
  })

  mainEmitLanguage.listen(async ({ lang }) => ({ lang }))
  mainEmitEndBreak.listen(async () => ({}))
}
