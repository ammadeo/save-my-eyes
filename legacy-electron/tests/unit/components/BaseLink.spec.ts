import { fireEvent } from '@testing-library/vue'
import { Base } from '@/utils/tests/core'
import { Generate } from '@/utils/tests/dataGenerator'
import Component from '@/components/BaseLink.vue'

import electron from 'electron'
jest.mock('electron', () => ({
  shell: {
    openExternal: jest.fn(),
  },
}))
const linkText = Generate.string('linkText')
const linkUrl = Generate.string('linkUrl')
const base = new Base(Component, {
  props: {
    href: linkUrl,
  },
  slots: {
    default: linkText,
  },
})

describe('components/BaseLink.vue', () => {
  test('has default slot', () => base.testHasSlot())

  test('call shell open external on click', async () => {
    const { getByText } = base.render()
    const Link = getByText(linkText)
    await fireEvent.click(Link)
    const localHost = 'http://localhost/'
    expect(electron.shell.openExternal).toHaveBeenCalledWith(
      localHost + linkUrl
    )
  })
})
