import { render, fireEvent, getNodeText } from '@testing-library/vue'
import Component from '@/components/IndexIdea.vue'
import { Base } from '@/utils/tests/core'
const base = new Base(Component, {
  methods: {
    random() {
      return 0
    },
  },
})

describe('components/IndexIdea.vue', () => {
  test('render 1 card with title, content and image', () => {
    const { getByTestId } = base.render()
    const IdeaTitle = getByTestId('idea-title')
    expect(IdeaTitle).toBeVisible()
    expect(getNodeText(IdeaTitle).length).toBeGreaterThan(10)

    const IdeaContent = getByTestId('idea-content')
    expect(IdeaContent).toBeVisible()
    expect(getNodeText(IdeaContent).length).toBeGreaterThan(10)

    const IdeaImg = getByTestId('idea-img')
    expect(IdeaImg).toBeVisible()
    expect(IdeaImg.getAttribute('alt')?.length).toBeGreaterThan(5)
  })
})
