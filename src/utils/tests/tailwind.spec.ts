import { whitelist, Classes } from '../config/tailwind'
describe('utils/config/tailwind.js', () => {
  test('Classes can generate correct classes with prefix and arg', () => {
    const expectedClasses = ['hover:bg-secondary-50', 'hover:bg-secondary-100']
    const generatedClasses = new Classes('bg').add(
      'hover',
      ['secondary', 50],
      ['secondary', 100]
    ).val
    expect(expectedClasses).toStrictEqual(generatedClasses)
  })
  test('setArg is setting correct arg', () => {
    const expectedClasses = [
      'bg-secondary-light-50',
      'bg-secondary-light-100',
      'bg-secondary-50',
      'bg-secondary-100'
    ]
    const generatedClasses = new Classes('bg')
      .setArg('secondary', 'light')
      .add('', 50, 100)
      .setArg('secondary')
      .add('', 50, 100).val
    expect(expectedClasses).toStrictEqual(generatedClasses)
  })
  test('whitelist include base classes', () => {
    expect(whitelist).toContain('body')
    expect(whitelist).toContain('html')
    expect(whitelist).toContain('nuxt-progress')
  })
})
