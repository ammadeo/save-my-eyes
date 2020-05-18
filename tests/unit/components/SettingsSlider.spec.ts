import { render } from '@testing-library/vue'
import Component from '@/components/SettingsSlider.vue'
import { Generate } from '@/utils/tests/dataGenerator'

const props = {
  value: 150,
  max: 60,
  center: 15,
  min: 2,
  scale: 10,
  step: 1,
  suffix: Generate.string('suffix'),
  name: Generate.string('name'),
  additionalValidator: jest.fn(),
}

const thumbText = (
  value = props.value,
  scale = props.scale,
  suffix = props.suffix
) => `${value / scale} ${suffix}`

const thumbStyle = (percentage: number) => ({
  left: `${percentage}%`,
  transform: `translate(-${percentage}%)`,
})
describe('components/SettingsSlider.vue', () => {
  test('has scaled value with suffix ', async () => {
    const { getByText } = render(Component, {
      props,
    })

    const span = getByText(thumbText())

    expect(span).toBeVisible()
  })

  describe('thumb position styles', () => {
    test('if value === min set to 0', () => {
      const { getByText } = render(Component, {
        props: {
          ...props,
          value: props.min * props.scale,
        },
      })
      const ThumbSpan = getByText(thumbText(props.min * props.scale))
      expect(ThumbSpan).toBeVisible()
      const Thumb = ThumbSpan?.parentElement?.parentElement
      // console.log(Thumb.style)
      expect(Thumb).toHaveStyle(thumbStyle(0))
    })
    test('if value === center set to half', () => {
      const { getByText } = render(Component, {
        props: {
          ...props,
          value: props.center * props.scale,
        },
      })
      const ThumbSpan = getByText(thumbText(props.center * props.scale))
      expect(ThumbSpan).toBeVisible()
      const Thumb = ThumbSpan?.parentElement?.parentElement
      // console.log(Thumb.style)

      expect(Thumb).toHaveStyle(thumbStyle(50))
    })
    test('if value === center do NOT set to half', () => {
      const { getByText } = render(Component, {
        props: {
          ...props,
          value: (props.center + 1) * props.scale,
        },
      })
      const ThumbSpan = getByText(thumbText((props.center + 1) * props.scale))
      expect(ThumbSpan).toBeVisible()
      const Thumb = ThumbSpan?.parentElement?.parentElement
      // console.log(Thumb.style)

      expect(Thumb).not.toHaveStyle(thumbStyle(50))
    })

    test('if value === max set to full', () => {
      const { getByText } = render(Component, {
        props: {
          ...props,
          value: props.max * props.scale,
        },
      })
      const ThumbSpan = getByText(thumbText(props.max * props.scale))
      expect(ThumbSpan).toBeVisible()
      const Thumb = ThumbSpan?.parentElement?.parentElement
      // console.log(Thumb.style)

      expect(Thumb).toHaveStyle(thumbStyle(100))
    })
  })
})
