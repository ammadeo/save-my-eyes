import { render } from '@testing-library/vue'
import Component from '@/components/HelpInfo.vue'

describe('components/HelpInfo.vue', () => {
  test('has content', () => {
    const { getByText } = render(Component)

    expect(getByText('Try one of these')).toBeVisible()
  })
})
