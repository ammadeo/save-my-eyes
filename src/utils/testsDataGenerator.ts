export const Generate = {
  string: (name = '') =>
    `__test-string__${name ? `${name}-` : ''}${Math.random()
      .toString(36)
      .substr(2, 9)}__`,

  number: (scale = 0) => Math.random() * 10 ** scale,

  object: (keys, withType = 'string') =>
    keys.reduce((all, key) => ({ ...all, [key]: Generate[withType]() }), {}),

  array: (length = 10, withType = 'string') => {
    const array = []
    for (let u = 0; u < length; u++) {
      array[u] = Generate[withType]()
    }
    return array
  }
}
