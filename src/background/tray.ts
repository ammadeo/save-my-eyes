import { Tray } from 'electron'
import { isProdBuild } from './env'
import { createWindowTray } from './windows'
import { getUserSettingsStore, TypedStore } from './db'
import { formatDistanceStrict, addSeconds } from 'date-fns'
import { pl, enGB } from 'date-fns/locale'
import ElectronStore from 'electron-store'
import { appIcon } from './paths'

const getNextBreakIn = (store: ElectronStore<TypedStore>) => {
  const every = store.get('breaks').every
  const now = new Date()
  return formatDistanceStrict(now, addSeconds(now, every), {
    roundingMethod: 'floor',
    locale: store.get('lang') === 'en' ? enGB : pl,
  })
}

const generateBallonContent = () => {
  const store = getUserSettingsStore()
  const nextBreakIn = getNextBreakIn(store)
  return store.get('lang') === 'en'
    ? `Your eyes are protected. Next break will start in ${nextBreakIn}. Click to find out more`
    : `Dbamy o Twoje oczy. Następna przerwa rozpocznie się za ${nextBreakIn}. Kliknij, aby dowiedzieć się więcej`
}

export const useTray = () => {
  const tray = new Tray(appIcon)
  tray.setToolTip(
    isProdBuild ? 'Save your eyes' : 'Save your eyes (Development)'
  )
  tray.on('click', createWindowTray)
  tray.on('right-click', createWindowTray)
  tray.on('balloon-click', createWindowTray)
  tray.displayBalloon({
    icon: appIcon,
    title: 'Save My Eyes',
    content: generateBallonContent(),
  })
  return tray
}
