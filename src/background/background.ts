import { app } from 'electron'
import serve from 'electron-serve'
import { exitOnChange } from './helpers/development'
import { useTray } from './helpers/tray'
import { isProd, isProdBuild, isDevProdTest } from './helpers/env'
import { setNewBreak } from './helpers/breaker'
import { useIpcMain } from './helpers/ipc'

if (isProdBuild) {
  serve({ directory: 'app' })
} else {
  exitOnChange()
  app.setPath('userData', `${app.getPath('userData')} (development)`)
}

;(async () => {
  await app.whenReady()

  useIpcMain()
  app.tray = useTray()

  setNewBreak()
})()

app.on('window-all-closed', (e) => e.preventDefault())
