import {
  format as fnsFormat,
  formatDistanceStrict as fnsFormatDistanceStrict,
} from 'date-fns'
import { pl, enGB } from 'date-fns/locale'
import store, { RootStore } from '@/store'
import { I18n } from '@/store/i18n'

interface I18nState extends RootStore {
  i18n: I18n
}

export const format: typeof fnsFormat = (date, format, options) => {
  return fnsFormat(date, format, {
    locale:
      ((store.state as I18nState)?.i18n?.lang ?? 'en') === 'pl' ? pl : enGB,
    ...options,
  })
}

export const formatDistanceStrict: typeof fnsFormatDistanceStrict = (
  date,
  format,
  options
) => {
  return fnsFormatDistanceStrict(date, format, {
    locale:
      ((store.state as I18nState)?.i18n?.lang ?? 'en') === 'pl' ? pl : enGB,
    ...options,
  })
}
