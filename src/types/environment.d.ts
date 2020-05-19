declare global {
  namespace NodeJS {
    interface ProcessEnv {
      IS_TEST: boolean | undefined
      [key: string]: boolean | string | undefined
    }
  }
}

// If this file has no import/export statements (i.e. is a script)
// convert it into a module by adding an empty export statement.
export {}
