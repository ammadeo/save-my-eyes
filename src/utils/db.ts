import { FixLog as FixLogTemplate } from '@/types/settings'
import { formatDistanceStrict } from './dateFnsI18n'
import { I18nGlobal, Languages, TranslateResult } from '@/store/i18n'

export type FixLogCode =
  | 'shortEvery'
  | 'shortLast'
  | 'longEvery'
  | 'longLast'
  | 'lang'
  | 'sound'

export type FixLog = FixLogTemplate<number, FixLogCode>
export interface FixLogSettings extends FixLogTemplate<number, FixLogCode> {
  message: string
}

export class FixNumber {
  private value: number
  constructor(private readonly originalValue: number) {
    this.value = originalValue
  }
  private changed() {
    return this.value !== this.originalValue
  }
  min(minimum: number) {
    this.value = Math.max(this.value, minimum)
    return this
  }
  max(maximum: number) {
    this.value = Math.min(this.value, maximum)
    return this
  }
  round() {
    this.value = Math.round(this.value)
    return this
  }
  toClosest(step: number) {
    this.value = Math.round(this.value / step) * step
    return this
  }
  val() {
    return {
      value: this.value,
      original: this.originalValue,
      changed: this.changed(),
    }
  }
}
export enum TimeFormat {
  seconds,
  minutes,
}

interface FixingResult {
  value: number
  original: number
  changed: boolean
}

export class FixSettings {
  private readonly fixLog: FixLogSettings[] = []
  constructor(
    private readonly translateGlobal: (id: keyof I18nGlobal) => string,
    private readonly language: Languages
  ) {}
  private format(from: number, to: number, name: TranslateResult) {
    if (this.language === 'pl')
      return `Naprawiam ${name.pl} z ${this.formatNumber(
        from
      )} na ${this.formatNumber(to)}`
    return `Fixing ${name.en} from ${this.formatNumber(
      from
    )} to ${this.formatNumber(to)}`
  }

  private formatNumber(value: number) {
    if (value > 60) return `${Math.round(value / 60)}\u00A0min.`
    return `${value}\u00A0${this.translateGlobal('secondsSuffix')}`
  }

  fix(
    original: number,
    fixes: (fixer: FixNumber) => FixingResult,
    code: FixLogCode,
    en: string,
    pl: string
  ): number {
    const { value, changed } = fixes(new FixNumber(original))
    if (changed)
      this.fixLog.push({
        code: code,
        name: {
          en,
          pl,
        },
        from: original,
        to: value,
        message: this.format(original, value, { en, pl }),
      })
    return value
  }
  get log() {
    return this.fixLog
  }
}
