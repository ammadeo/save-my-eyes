declare namespace NodeJS {
  export interface ProcessEnv {
    IS_TEST: string | undefined
    [key: string]: string | undefined
  }
}

// If this file has no import/export statements (i.e. is a script)
// convert it into a module by adding an empty export statement.
export {}
