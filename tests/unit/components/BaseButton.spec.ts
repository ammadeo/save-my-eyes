import Component from '@/components/BaseButton.vue'
import { Base } from '@/utils/tests/core'
const base = new Base(Component)

describe('components/BaseButton.vue', () => {
  test('has content slot', () => base.testHasSlot())
  test('on click emit click', () => base.testEmitter())

  test('set secondary color classes on primary prop', async () => {
    const renderer = base.render()
    const root = base.selectRoot(renderer)

    const bottomPart = root.firstChild  as HTMLElement
    const topPart = root.lastChild as HTMLElement
    const parts = [bottomPart, topPart]

    parts.forEach(part => {
      const secondaryClasses = part.classList.toString()
      expect(secondaryClasses).toMatch('bg-secondary')
      expect(secondaryClasses).toMatch('group-hocus:bg-secondary')
      expect(secondaryClasses).not.toMatch('bg-primary')
    });

    await renderer.updateProps({ primary: true })
    parts.forEach(part => {
      const primaryClasses = part.classList.toString()
      expect(primaryClasses).toMatch('bg-primary')
      expect(primaryClasses).toMatch('group-hocus:bg-primary')
      expect(primaryClasses).not.toMatch('bg-secondary')
    })
  })
})
