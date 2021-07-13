import { render } from '@testing-library/vue'
import Component from '@/components/IndexSettings.vue'

jest.mock('vue-cli-plugin-electron-builder/lib', () => ({
  createProtocol: () => {},
}))

describe('components/IndexSettings.vue', () => {
  test.todo('implement tests!')
  test('', () => {
    const { getByText } = render(Component)
  })
})
