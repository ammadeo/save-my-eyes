class Data<T> {
  constructor(private data: T) {}
  get value() {
    return this.data
  }
  set value(to) {
    this.data = typeof to === 'object' ? { ...to } : to
  }
}

export const breakIndex = new Data(0)
export const breakId = new Data(0)

export const lastSchedulerJobDate = new Data(new Date().toISOString())
export const lastSchedulerJobLength = new Data(0)
