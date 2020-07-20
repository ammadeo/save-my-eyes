import { fireEvent } from '@testing-library/vue'
import { Base } from '@/utils/tests/core'
import Component from '@/components/BaseLink.vue'
const base = new Base(Component, {
  props: {
    href: '#home',
  },
})

describe('components/BaseLink.vue', () => {
  test('has default slot', () => base.testHasSlot())

  test('')
})
