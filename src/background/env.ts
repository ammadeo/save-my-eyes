import { testProd } from './env.changeable'

//? for easier testing production long task
export const isDevProdTest = process.env.NODE_ENV === 'development' && testProd
//? for testing real prod in dev environment
export const isProd = process.env.NODE_ENV === 'production' || testProd
//? only for build process do not change by force
export const isProdBuild = process.env.NODE_ENV === 'production'

process.env.IS_TEST = isProdBuild ? undefined : 'true'
