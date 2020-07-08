import { fireEvent } from '@testing-library/vue'
import { Base } from '@/utils/tests/core'
import Component from '@/components/BaseLink.vue'
const base = new Base(Component)

describe('components/BaseLink.vue', () => {
  test.todo('implement tests!')
  test('', async () => {
    const { getByText } = base.render()
  })
})
