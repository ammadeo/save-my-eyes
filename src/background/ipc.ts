import {
  breakIndex,
  lastSchedulerJobDate,
  lastSchedulerJobLength,
} from './store'
import { setNewBreak, NewBreakOptions } from './breaker'
import { isProdBuild } from './env'
import { app, ipcMain, ipcRenderer } from 'electron'
export const channelSetBreak = 'set-break'
export const channelGetBreakCount = 'break-count'
export const channelCloseApp = 'close-app'
export const channelGetBreakerData = 'breaker-data'

export interface OptionsSetBreak {
  forceNextBreakIn: number
}

class IpcChanel<RendererAskPayload extends {}, RendererAskAnswer extends {}> {
  private readonly mainChanelId: string
  private readonly rendererChanelId: string
  constructor(baseChanelId: string){
    this.mainChanelId = `${baseChanelId}-main`
    this.rendererChanelId = `${baseChanelId}-renderer`
  }

  renderer(){
    const ask = async (options: RendererAskPayload): Promise<RendererAskAnswer> => 
      new Promise((resolve, reject)=>{
        ipcRenderer.on(this.mainChanelId, (_event:Event, answer: RendererAskAnswer) => {
          resolve(answer)
        })
        if(!isProdBuild){
          setTimeout(()=>{ console.error(`timeout while waiting for ${this.mainChanelId} to response`)
          reject()}, 500)
        }
        ipcRenderer.send(this.rendererChanelId, options)
      })
    


    // todo if needed
    // const tell = async (): Promise<void> => {

    // }

    // const listen = () =>{

    // }

    return {
      ask
    }
  }

  main(){
    const tell = () => {

    }

    const listen = () => {
      ipcMain.on(this.rendererChanelId, (event, payload: RendererAskPayload) => {
        event.reply()
      })
    }
    return {
      listen
}
  }

}

class IpcChanelFactory {
  private static index = 0
  private static generateId() {
    this.index++
    return `auto-generated-${this.index}`
  }
  static create() {
    const id = this.generateId()
    return new IpcChanel(id)
  }
}

//? ipc for renderer
export const rendererGetBreakIndex = async (): Promise<number> => {
  return await ipcRenderer.callMain(channelGetBreakCount)
}

export const rendererGetBreakerData = async (): Promise<{
  lastSchedulerJobDate: typeof lastSchedulerJobDate.value
  lastSchedulerJobLength: typeof lastSchedulerJobLength.value
}> => {
  console.log("ipc before call:", channelGetBreakerData)
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
    console.log("ipc before answer:", channelGetBreakerData, 'lastSchedulerJobDate.value', lastSchedulerJobDate.value, 'lastSchedulerJobLength.value', lastSchedulerJobLength.value)
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
