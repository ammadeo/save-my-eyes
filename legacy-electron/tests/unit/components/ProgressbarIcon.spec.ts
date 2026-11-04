import { render } from '@testing-library/vue'
import Component from '@/components/ProgressbarIcon.vue'
import { Base } from '@/utils/tests/core'

const props = {
  value: 30,
  max: 100,
  min: 0,
  icon: 'start',
}

const base = new Base(Component, { props })
describe('components/ProgressbarIcon.vue', () => {
  test('render progressbar component', () => {
    const { getByRole, debug } = base.render()
    expect(getByRole('progressbar')).toBeVisible()
  })
  test('render icon', () => {
    const { getByAltText, debug } = base.render()
    expect(getByAltText('start icon')).toBeVisible()
  })
})
