/* eslint-disable @typescript-eslint/no-var-requires */
const { colors } = require('tailwindcss/defaultTheme')

const plugin = require('tailwindcss/plugin')
/*
 ** TailwindCSS Configuration File
 **
 ** Docs: https://tailwindcss.com/docs/configuration
 ** Default: https://github.com/tailwindcss/tailwindcss/blob/master/stubs/defaultConfig.stub.js
 */

// const cardBottomMargin = 'spacing.2'

module.exports = {
  purge: {
    enabled: false,
  },
  theme: {
    colors: {
      black: colors.black,
      white: colors.white,
      gray: colors.gray,
      transparent: colors.transparent,
      warn: colors.orange,
      secondary: {
        50: '#E8EAF6',
        100: '#C5CAE9',
        200: '#9FA8DA',
        300: '#7986CB',
        400: '#5C6BC0',
        500: '#3F51B5',
        600: '#3949AB',
        700: '#303F9F',
        800: '#283593',
        900: '#1A237E',
        1000: '#121959',
        1050: '#10164F',
        1075: '#0F154A',
        1100: '#030943',
        1200: '#020630',
      },
      primary: {
        50: '#E3F2FD',
        100: '#BBDEFB',
        200: '#90CAF9',
        300: '#64B5F6',
        400: '#42A5F5',
        500: '#2196F3',
        600: '#1E88E5',
        700: '#1976D2',
        800: '#1565C0',
        900: '#0D47A1',
      },
    },
    fontFamily: {
      display: ['comfortaa', 'roboto', 'sans-serif'],
      body: ['Source Sans Pro', 'roboto', 'sans-serif'],
    },
    fontWeight: {
      light: 300,
      normal: 400,
      medium: 500,
      semibold: 600,
    },
    borderWidth: {
      default: '1px',
      '0': '0',
      '2': '2px',
      '4': '4px',
      '6': '6px',
      '8': '8px',
    },
    extend: {
      gridTemplateColumns: {
        base:
          'minmax(min-content, 5fr) minmax(2rem, 4rem) minmax(min-content, 2fr)',
      },
      gridTemplateRows: {
        base: 'auto auto 1fr auto',
      },
      inset: {
        full: '100%',
      },
      translate: (theme) => ({
        '-card-40': `calc(${theme('spacing.40')} - ${theme(
          'spacing.2'
        )} - 100%)`,
        '-card-48': `calc(${theme('spacing.48')} - ${theme(
          'spacing.2'
        )} - 100%)`,
        '-card-56': `calc(${theme('spacing.56')} - ${theme(
          'spacing.2'
        )} - 100%)`,
        '-card-64': `calc(${theme('spacing.64')} - ${theme(
          'spacing.2'
        )} - 100%)`,
      }),
      spacing: {
        '11': '2.75rem',
        '18': '4.5rem',
        '80': '20rem',
        '120': '30rem',
      },
      minHeight: (theme) => ({
        12: theme('spacing.12'),
      }),
      maxHeight: (theme) => ({
        'screen-16': `calc(100vh - ${theme('spacing.16')})`,
        'screen-24': `calc(100vh - ${theme('spacing.24')})`,
        'screen-32': `calc(100vh - ${theme('spacing.32')})`,
      }),
      minWidth: (theme) => theme('spacing'),
      borderRadius: {
        inherit: 'inherit',
      },
      boxShadow: (theme) => ({
        revers: `0 -1px 3px 0 rgba(0, 0, 0, 0.1), 0 -1px 2px 0 rgba(0, 0, 0, 0.06)`,
        'lg-revers': `0 -10px 15px -3px rgba(0, 0, 0, 0.1), 0 -4px 6px -2px rgba(0, 0, 0, 0.05)`,
        'xl-revers': `0 -20px 25px -5px rgba(0, 0, 0, 0.1), 0 -10px 10px -5px rgba(0, 0, 0, 0.04)`,
        'inner-1': `inset 0 -${theme('spacing.px')} ${theme(
          'spacing.1'
        )} 0 rgba(0, 0, 0, 0.2)`,
        'inner-2-top-2': `inset 0 ${theme('spacing.2')} ${theme(
          'spacing.2'
        )} 0 rgba(0, 0, 0, 0.17)`,
      }),
    },
  },
  variants: {
    boxShadow: ['responsive', 'hover', 'focus', 'group-active', 'active'],
    margin: ['responsive', 'last'],
    borderWidth: ['responsive', 'hover', 'focus', 'active'],
    overflow: [
      'responsive',
      'hover',
      'focus',
      // 'focus-within'
    ],
    textTransform: ['first-letter'],
    translate: [
      'responsive',
      'hover',
      'focus',
      'active',
      'group-active',
      // 'focus-within',
      // todo fix focus within or add support by js
    ],
    backgroundColor: [
      'responsive',
      'hover',
      'focus',
      'focus-within',
      'group-hover',
      'group-focus',
      'group-hocus',
    ],
  },
  plugins: [
    require('tailwindcss-interaction-variants'),
    plugin(function({ addVariant, e }) {
      addVariant('first-letter', ({ modifySelectors, separator }) => {
        modifySelectors(({ className }) => {
          return `.${e(`first-letter${separator}${className}`)}::first-letter`
        })
      })
    }),
  ],
  corePlugins: {},
}
