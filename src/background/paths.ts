import { isProdBuild } from './env'
import { join } from 'path'
import { app } from 'electron'
const appPath = () => {
  if (app) return app.getAppPath()
  throw new Error('path icon: no app instance')
}
export const appIcon = () =>
  isProdBuild ? join(appPath(), 'icon.png') : join('public', 'icon.png')
