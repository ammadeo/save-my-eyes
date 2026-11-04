import { TranslateResult } from '@/store/i18n'

export interface FixLog<
  T extends number | string = number | string,
  Code extends string = string
> {
  code: Code
  name: TranslateResult
  from: T
  to: T
}
