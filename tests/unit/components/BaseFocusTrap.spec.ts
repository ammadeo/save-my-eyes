import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/BaseFocusTrap.vue'
import { Base } from '@/utils/tests/core'
import { Generate } from '@/utils/tests/dataGenerator'
import { VNode } from 'vue'
const testId = Generate.string('test')

const base = new Base(Component, {
  props: {
    active: true,
  },
  slots: {
    default: `<div data-testid="${testId}"><button>click</button></div>`,
  },
})

describe('components/BaseFocusTrap.vue', () => {
  test('has default slot', () => base.testHasSlot())

  test.todo('has set focus trap on active')
})
