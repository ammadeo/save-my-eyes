const LicenseWebpackPlugin = require('license-webpack-plugin')
  .LicenseWebpackPlugin

module.exports = {
  configureWebpack: {
    plugins: [
      new LicenseWebpackPlugin({
        preferredLicenseTypes: ['MIT'],
        unacceptableLicenseTest: (licenseType) => licenseType === 'GPL',
      }),
    ],
  },

  chainWebpack: (config) =>
    config.module
      .rule('vue')
      .use('vue-svg-inline-loader')
      .loader('vue-svg-inline-loader')
      .options({
        /* ... */
      })
      .end(),

  pluginOptions: {
    electronBuilder: {
      builderOptions: {
        copyright: 'Copyright © 2020 ${author}',
        win: {
          icon: './public/icon.png',
          target: 'nsis',
        },
        nsis: {
          deleteAppDataOnUninstall: true,
          createDesktopShortcut: false,
          createStartMenuShortcut: false,
        },
      },
    },
  },
}
