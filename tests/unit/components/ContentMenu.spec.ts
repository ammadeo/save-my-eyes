import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/ContentMenu.vue'
import { Generate } from '@/utils/tests/dataGenerator'

describe('components/TheMenu.vue', () => {
  test('has next break time info', async () => {
    const { getByText } = render(Component)

    const ContentBox = getByText('next long break in 13 minutes')

    expect(ContentBox).toBeVisible()
  })

  test('has start a long break now button', async () => {
    const { getByText, emitted } = render(Component)

    const Button = getByText('start a long break now', { exact: false })
    expect(Button).toBeVisible()
    await fireEvent.click(Button)
    expect(emitted().run[0]).toStrictEqual(['start-long-break'])
  })

  test('has stop protection button', async () => {
    const { getByText, emitted } = render(Component)

    const Button = getByText('stop protection', { exact: false })
    expect(Button).toBeVisible()
    await fireEvent.click(Button)
    expect(emitted().run[0]).toStrictEqual(['open-stop-protection'])
  })

  test('has settings button', async () => {
    const { getByText, emitted } = render(Component)

    const Button = getByText('settings', { exact: false })
    expect(Button).toBeVisible()
    await fireEvent.click(Button)
    expect(emitted().run[0]).toStrictEqual(['open-settings'])
  })
})
