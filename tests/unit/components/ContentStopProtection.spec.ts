import { fireEvent, waitFor } from '@testing-library/vue'
import Component from '@/components/ContentStopProtection.vue'
import { Base } from '@/utils/tests/core'
import { rendererCloseApp, rendererSetNextBreak } from '@/background/ipc'
const base = new Base(Component)
const askToClose = (rendererCloseApp.ask as unknown) as jest.Mock<
  typeof rendererCloseApp.ask
>
const askToBreak = (rendererSetNextBreak.ask as unknown) as jest.Mock<
  typeof rendererSetNextBreak.ask
>
jest.mock('vue-cli-plugin-electron-builder/lib', () => ({
  createProtocol: () => {},
}))

jest.mock('@/background/ipc')

describe('components/ContentStopProtection.vue', () => {
  test('has break timeout buttons', async () => {
    const { getByText } = base.render()
    const texts = ['1 hour', '2 hours', '3 hours']
    texts.forEach((text: string) => {
      const Button = getByText(text)
      expect(Button).toBeVisible()
    })
  })
  test('has close app button', () =>
    base.testHtmlVisibility(({ getByText }) => getByText('for this session')))

  test('has working close app button', async () => {
    const { getByTestId } = base.render()
    const Button = getByTestId('button-close-app')
    await fireEvent.click(Button)
    expect(askToClose).toHaveBeenCalledTimes(1)
  })

  test('has working break timeout buttons', async () => {
    const { getAllByTestId, emitted } = base.render()
    const Button = getAllByTestId('button-pause-break')[0]
    await fireEvent.click(Button)
    expect(askToBreak).toHaveBeenCalledWith({
      forceNextBreakIn: 60 * 60,
    })
    await waitFor(() => {
      expect(emitted().close).toBeTruthy()
    })
  })
})
