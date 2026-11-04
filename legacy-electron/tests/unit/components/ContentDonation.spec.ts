import { fireEvent } from '@testing-library/vue'
import { Base } from '@/utils/tests/core'
import Component from '@/components/ContentDonation.vue'
import electron from 'electron'

jest.mock('electron', () => ({
  shell: {
    openExternal: jest.fn(),
  },
  remote: {
    getCurrentWindow: jest.fn(() => ({
      close: jest.fn(),
    })),
  },
}))

const base = new Base(Component)

describe('components/ContentDonation.vue', () => {
  test('fire shell openExternal on click', async () => {
    const { getByText } = base.render()
    const Button = getByText('Buy me a coffee')
    await fireEvent.click(Button)
    expect(electron.shell.openExternal).toBeCalled()
  })
})
