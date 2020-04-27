module.exports = {
  preset: "@vue/cli-plugin-unit-jest/presets/typescript-and-babel",
  testMatch: [
    "**/tests/unit/**/*.spec.[jt]s?(x)",
    "**/tests/e2e/**/*.spec.[jt]s?(x)",
    "**/__tests__/*.[jt]s?(x)"
  ],
  transformIgnorePatterns: ["/node_modules/", "/dist_electron/"]
};
