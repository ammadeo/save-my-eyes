import { Tray } from 'electron'
import { isProdBuild } from './env'
import { createWindowTray } from './windows'
import { getUserSettingsStore, TypedStore } from './db'
import { formatDistanceStrict, addSeconds } from 'date-fns'
import { pl, enGB } from 'date-fns/locale'
import ElectronStore from 'electron-store'
import { appIcon } from './paths'
import { debug } from 'electron-log'

const getNextBreakIn = (store: ElectronStore<TypedStore>) => {
  const every = store.get('breaks').every
  debug('tray balloon get breaks every', every)
  const now = new Date()
  return formatDistanceStrict(now, addSeconds(now, every), {
    roundingMethod: 'floor',
    locale: store.get('lang') === 'en' ? enGB : pl,
  })
}

const generateBalloonContent = () => {
  const store = getUserSettingsStore()
  debug('tray balloon receive store')
  const nextBreakIn = getNextBreakIn(store)
  debug('tray balloon next break in', nextBreakIn)
  debug('tray balloon get lang', store.get('lang'))
  return store.get('lang') === 'en'
    ? `Your eyes are protected. Next break will start in ${nextBreakIn}. Click on icon below to find out more`
    : `Dbamy o Twoje oczy. Następna przerwa rozpocznie się za ${nextBreakIn}. Kliknij ikonę poniżej, aby dowiedzieć się więcej`
}

export const useTray = () => {
  const tray = new Tray(appIcon)
  debug('tray created')
  tray.setToolTip(
    isProdBuild ? 'Save your eyes' : 'Save your eyes (Development)'
  )
  debug('tray set tooltip')
  tray.on('click', createWindowTray)
  tray.on('right-click', createWindowTray)
  debug('tray set click handlers')
  tray.displayBalloon({
    icon: appIcon,
    title: 'Save My Eyes',
    content: generateBalloonContent(),
  })
  debug('tray displayed balloon')
  return tray
}
