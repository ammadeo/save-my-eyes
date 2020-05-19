import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/CardFocusable.vue'
import { Base } from '@/utils/tests/core'

const base = new Base(Component)

describe('components/CardFocusable.vue', () => {
  test('has default slot', () => base.testHasSlot())
  test('on mouseOver emit focusin', () =>
    base.testEmitter(undefined, 'mouseOver', 'focusin'))
  test('on mouseLeave emit focusout', () =>
    base.testEmitter(undefined, 'mouseLeave', 'focusout'))
})
