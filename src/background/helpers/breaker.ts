import { scheduleJob } from 'node-schedule'
import { addSeconds } from 'date-fns'
import { isProd, isProdBuild, isDevProdTest } from './env'
import { createWindowIndex } from './windows'
import { breakIndex } from './store'
import { getUserSettingsStore } from './db'
import log from 'electron-log'

let breakSchedule

const getEveryFromDB = () => {
  return getUserSettingsStore().get('breaks').every
}

const calculateNextBreak = (nextBreakIn) => {
  return addSeconds(new Date(), isProdBuild ? nextBreakIn : 3)
}

export const setNewBreak = (forceBreakIn = undefined) => {
  const forced = !!forceBreakIn
  const nextBreakIn = forceBreakIn || getEveryFromDB()

  const nextBreak = calculateNextBreak(nextBreakIn)

  if (!forced) breakIndex.value++
  const keyBreakIndex = breakIndex.value
  if (breakSchedule) breakSchedule.cancel()
  log.log(
    'setNewBreak',
    'keyBreakIndex',
    keyBreakIndex,
    'breakIndex.value',
    breakIndex.value,
    'forced',
    forced,
    'nextBreak',
    nextBreak,
    'nextBreakIn',
    nextBreakIn
  )
  breakSchedule = scheduleJob(nextBreak, () => {
    if (keyBreakIndex === breakIndex.value) {
      createWindowIndex()
    }
  })
}
