const generatorAddPrefixAndSuffixIfDefine = (prefix = '', suffix = '') => (
  value
) => {
  if (!value) return ''
  let modifiedValue = value.toString()
  if (!modifiedValue.startsWith(prefix)) modifiedValue = prefix + modifiedValue
  if (!modifiedValue.endsWith(suffix)) modifiedValue = modifiedValue + suffix
  return modifiedValue
}

const addArg = generatorAddPrefixAndSuffixIfDefine('-')
const addPrefix = generatorAddPrefixAndSuffixIfDefine('', ':')

const generatorReduceToString = (modifier) => (values) => {
  if (Array.isArray(values)) {
    return values.reduce((acc, value) => acc + modifier(value), '')
  } else if (values) return modifier(values)
  return ''
}

const argsToString = generatorReduceToString(addArg)
const prefixesToString = generatorReduceToString(addPrefix)

const generateClass = (base, args, prefixes) => {
  const prefix = prefixesToString(prefixes)
  const arg = argsToString(args)
  return prefix + base + arg
}

class Classes {
  constructor(base) {
    this.base = base
    this.classes = []
    this.arg = ''
  }
  setArg(...args) {
    this.arg = argsToString(args)
    return this
  }
  pushClassByArgs(args, prefix) {
    args.forEach((arg) => {
      const stringifiedArg = this.arg + argsToString(arg)
      this.classes.push(generateClass(this.base, stringifiedArg, prefix))
    })
  }
  add(prefixes, ...args) {
    if (Array.isArray(prefixes))
      prefixes.forEach((prefix) => this.pushClassByArgs(args, prefix))
    else this.pushClassByArgs(args, prefixes)

    return this
  }
  log() {
    console.log('tailwind classes', this.classes)
    return this
  }
  get val() {
    return this.classes
  }
}

exports.Classes = Classes

const helpAutoBorderClasses = (elevation) => [
  ['r', elevation],
  ['b', elevation]
]

exports.whitelist = [
  'body',
  'html',
  'overflow-y-auto',
  ...new Classes('bg')
    .setArg('secondary')
    .add('', 300, 500, 700, 800)
    .add(['focus', 'hover'], 800)
    .setArg('secondary')
    .add('', 400).val,
  ...new Classes('border')
    .add(
      '',
      ...helpAutoBorderClasses(4),
      ...helpAutoBorderClasses(6),
      ...helpAutoBorderClasses(2)
    )
    .add('active', ...helpAutoBorderClasses(2))
    .setArg('secondary')
    .add('', 500, 700, 900, 1000)
    .add(['focus', 'hover'], 1000)
    .setArg('secondary')
    .add('', 600).val,
  ...new Classes('-translate')
    .setArg('y', 'card')
    .add('', 40)
    .add('md', 48)
    .add('lg', 56)
    .add('xl', 64).val
]
