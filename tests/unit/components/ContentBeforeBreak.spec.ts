import { render, waitFor } from '@testing-library/vue'
import Component from '@/components/ContentBeforeBreak.vue'
import { Base } from '@/utils/tests/core'
const base = new Base(Component)

jest.useFakeTimers()

describe('components/ContentBeforeBreak.vue', () => {
  test('has skip button', () => {
    const { getByText } = base.render()
    expect(getByText('Skip for 5 minutes')).toBeVisible()
  })

  test('has working progressbar', async () => {
    const { getByRole } = base.render()
    const Progressbar = getByRole('progressbar')
    expect(Progressbar).toBeVisible()
    const ProgressDrawer = [...Progressbar.children][1]
    expect(ProgressDrawer).toHaveStyle('transform: translateX(-100%)')
    jest.runAllTimers()
    await waitFor(() =>
      expect(ProgressDrawer).not.toHaveStyle('transform: translateX(-100%)')
    )
  })
})
