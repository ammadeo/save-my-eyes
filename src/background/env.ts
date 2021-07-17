//? for testing real production build in debug mode
export const debugProd = process.env.VUE_APP_PRODUCTION_DEBUG == "true"
//? for easier testing production long task
export const isDevProdTest = process.env.NODE_ENV === 'development' && process.env.VUE_APP_DEVELOPMENT_TEST_PRODUCTION == "true"
//? for testing real prod in dev environment
export const isProd = process.env.NODE_ENV === 'production' || process.env.VUE_APP_DEVELOPMENT_TEST_PRODUCTION == "true"
//? only for build process do not change by force
export const isProdBuild = process.env.NODE_ENV === 'production'

process.env.IS_TEST = isProdBuild ? undefined : 'true'
