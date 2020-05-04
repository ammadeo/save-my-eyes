interface Generate {
  string: (name?: string) => string

  number: (scale?: number) => number

  // object: <Key extends keyof typeof Generate>(keys?: string[], withType?: Key) => Record<NonNullable<typeof keys>[number], Generate[Key]>,

  // array: <Key extends keyof typeof Generate>(length?: number, withType?: Key) => Generate[Key][]
}

export const Generate: Generate = {
  string: (name = '') =>
    `__test-string__${name ? `${name}-` : ''}${Math.random()
      .toString(36)
      .substr(2, 9)}__`,

  number: (scale = 0) => Math.random() * 10 ** scale,

  // object: (keys: string[] = [], withType: keyof typeof Generate = 'string') =>
  //   keys.reduce((all, key) => ({ ...all, [key]: Generate[withType]() }), {}),

  // array: (length = 10, withType: keyof typeof Generate = 'string') => {
  //   const array = []
  //   for (let u = 0; u < length; u++) {
  //     array[u] = Generate[withType]()
  //   }
  //   return array
  // }
}
