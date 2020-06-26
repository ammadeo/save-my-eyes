export interface FixLog<T extends number | string = number | string> {
  code: string
  from: T
  to: T
}
