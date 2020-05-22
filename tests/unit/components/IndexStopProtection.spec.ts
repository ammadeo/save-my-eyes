import { render } from '@testing-library/vue'
import Component from '@/components/IndexStopProtection.vue'
import { Base } from '@/utils/tests/core'
const base = new Base(Component)

jest.mock('vue-cli-plugin-electron-builder/lib', () => ({
  createProtocol: () => {},
}))

describe('components/IndexStopProtection.vue', () => {
  test.todo('implement tests!')

  test('', () => {
    const { getByText } = render(Component)
  })
})
