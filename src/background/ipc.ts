import { expectCall } from '@/utils/tests/electron'

import {
  breakIndex,
  lastSchedulerJobDate,
  lastSchedulerJobLength,
} from './store'
import {createWindowIndexChildren, focusOn, setBackgroundOf} from './windows'
import { setNewBreak, NewBreakOptions } from './breaker'
import { isProdBuild } from './env'
import { app, ipcMain, ipcRenderer } from 'electron'
// export const channelSetBreak = 'set-break'
// export const channelGetBreakCount = 'break-count'
// export const channelCloseApp = 'close-app'
// export const channelGetBreakerData = 'breaker-data'

export interface OptionsSetBreak {
  forceNextBreakIn: number
}

class IpcChanel<RendererAskPayload extends {}, RendererAskAnswer extends {}> {
  private readonly mainChanelId: string
  private readonly rendererChanelId: string
  constructor(baseChanelId: string) {
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
  }

  readonly main = {
    listen: (
      answerHandler: (payload: RendererAskPayload) => RendererAskAnswer
    ) => {
      ipcMain.on(
        this.rendererChanelId,
        (event, payload: RendererAskPayload) => {
          event.reply(this.mainChanelId, answerHandler(payload))
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
  static create<RendererAskPayload extends {}, RendererAskAnswer extends {}>() {
    const id = this.generateId()
    return new IpcChanel<RendererAskPayload, RendererAskAnswer>(id)
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
} = IpcChanelFactory.create<{}, {}>()

export const {
  main: mainStartBreak,
  renderer: rendererStartBreak,
} = IpcChanelFactory.create<{}, {}>()

//? ipc for main
export const useIpcMain = () => {
  mainGetBreakData.listen(() => ({
    breakIndex: breakIndex.value,
    lastSchedulerJobDate: lastSchedulerJobDate.value,
    lastSchedulerJobLength: lastSchedulerJobLength.value,
  }))

  mainSetNextBreak.listen((options) => {
    setNewBreak(options)
    return {}
  })

  mainCloseApp.listen(() => {
    app.quit()
    return {}
  })

  mainStartBreak.listen(async () => {
    const indexKey = 'windowIndex'
    setBackgroundOf(indexKey)
    focusOn(indexKey)
    await createWindowIndexChildren()
    return {}
  })
}
