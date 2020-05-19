import { render } from '@testing-library/vue'
import Component from '@/components/IndexStopProtection.vue'
jest.mock('vue-cli-plugin-electron-builder/lib', () => ({
  createProtocol: () => {},
}))

describe('components/IndexStopProtection.vue', () => {
  test.todo('implement tests!')

  test('', () => {
    const { getByText } = render(Component)
  })
})
