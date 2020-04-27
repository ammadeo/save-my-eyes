module.exports = {
  preset: "@vue/cli-plugin-unit-jest/presets/typescript-and-babel",
  testMatch: [
    "**/tests/unit/**/*.spec.[jt]s?(x)",
    "**/tests/e2e/**/*.spec.[jt]s?(x)",
    "**/__tests__/*.[jt]s?(x)"
  ],
  transformIgnorePatterns: ["/node_modules/", "/dist_electron/"],
  moduleNameMapper: {
    "^~/(.*)$": "<rootDir>/src/$1",
    "^~~/(.*)$": "<rootDir>/src/$1",
    "^@/(.*)$": "<rootDir>/src/$1",
    "^vue$": "vue/dist/vue.common.js",
    "\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$":
      "<rootDir>/__mocks__/fileMock.js"
  },
  setupFilesAfterEnv: ["<rootDir>/jest.setup.js"]
};
