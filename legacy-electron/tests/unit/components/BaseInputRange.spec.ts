import { render } from '@testing-library/vue'
import Component from '@/components/BaseInputRange.vue'
import { Generate } from '@/utils/tests/dataGenerator'
import { Base } from '@/utils/tests/core'

const props = {
  value: 150,
  max: 60,
  min: 2,
  scale: 10,
  step: 1,
  suffix: Generate.string('suffix'),
  name: Generate.string('name'),
  additionalValidator: jest.fn(() => true),
  forceLarge: true,
}
const base = new Base(Component, { props })

const countDisplayValue = (value = props.value, scale = props.scale) =>
  Math.floor(value / scale).toString()

describe('components/BaseInputRange.vue', () => {
  test('has suffix ', async () => {
    const { getByText } = base.render()

    const span = getByText(props.suffix)
    expect(span).toBeVisible()
  })
  test('both inputs have min, max, step and value values', () => {
    const { getAllByDisplayValue } = base.render()
    const inputs = getAllByDisplayValue(countDisplayValue())

    inputs.forEach((input) => {
      expect(input).toHaveAttribute('max', props.max.toString())
      expect(input).toHaveAttribute('min', props.min.toString())
      expect(input).toHaveAttribute('step', props.step.toString())
    })
  })

  test('input has auto set width', async () => {
    const { getAllByDisplayValue, updateProps } = base.render()
    const input = getAllByDisplayValue(countDisplayValue())[0]
    expect(input).toHaveClass('w-6')
    await updateProps({
      scale: 1,
    })
    expect(input).toHaveClass('w-8')
    await updateProps({
      scale: 50,
    })
    expect(input).toHaveClass('w-4')
  })
  test('has min value with suffix displayed', () =>
    base.testPropInline(({ getByText }) =>
      getByText(`${props.min} ${props.suffix}`)
    ))
  test('has max value with suffix displayed', () =>
    base.testPropInline(({ getByText }) =>
      getByText(`${props.max} ${props.suffix}`)
    ))
  test('has name displayed', () =>
    base.testPropInline(({ getByText }) => getByText(props.name)))

  test('emit change on input of number type', () =>
    base.testEmitter(
      ({ getAllByDisplayValue }) =>
        getAllByDisplayValue(countDisplayValue())[0],
      'input'
    ))
  test('emit change on input of range type', () =>
    base.testEmitter(
      ({ getAllByDisplayValue }) =>
        getAllByDisplayValue(countDisplayValue())[1],
      'input'
    ))
})
