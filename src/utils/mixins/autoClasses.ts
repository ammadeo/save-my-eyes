import vue from 'vue'
const autoPrefix = (prefix: string) => (prefix ? `${prefix}:` : '')

export const AutoBorderClasses = vue.extend({
  methods: {
    autoBorderClasses(elevation = 4, prefix = '') {
      return [
        `${autoPrefix(prefix)}border-b-${elevation}`,
        `${autoPrefix(prefix)}border-r-${elevation}`
      ]
    }
  }
})

export const AutoColorClasses = vue.extend({
  methods: {
    autoColorClasses(color = 'secondary', intensity = '500', prefix = '') {
      return [
        `${autoPrefix(prefix)}bg-${color}-${intensity}`,
        `${autoPrefix(prefix)}border-${color}-${Number(intensity) + 200}`
      ]
    },
    autoColorSplit(color: string) {
      return color.split('-')
    }
  }
})

export const AutoFocusWithinCardClasses = vue.extend({
  methods: {
    autoFocusWithinCardClasses(isFocused: boolean) {
      return isFocused
        ? [
            'overflow-y-auto',
            '-translate-y-card-40',
            'md:-translate-y-card-48',
            'lg:-translate-y-card-56',
            'xl:-translate-y-card-64'
          ]
        : []
    }
  }
})
