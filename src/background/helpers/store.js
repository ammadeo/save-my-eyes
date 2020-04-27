class Data {
  constructor(initial) {
    this._data = initial
  }
  get value() {
    return this._data
  }
  set value(to) {
    this._data = to
  }
}

export const breakIndex = new Data(0)
