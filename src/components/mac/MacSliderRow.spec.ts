import { describe, expect, test } from "vitest";
import { render } from "@testing-library/vue";
import Component from "./MacSliderRow.vue";

const props = { label: "Length", min: 0, max: 15, scale: 60, suffix: "min." };
const output = (container: Element) => container.querySelector("output")?.textContent?.replace(/\s+/g, " ").trim();

describe("components/mac/MacSliderRow.vue", () => {
  test("shows value and suffix", () => {
    const { container } = render(Component, { props: { ...props, modelValue: 300 } });
    expect(output(container)).toBe("5 min.");
  });

  test("zero shows the suffix without a zeroLabel", () => {
    const { container } = render(Component, { props: { ...props, modelValue: 0 } });
    expect(output(container)).toBe("0 min.");
  });

  test("zeroLabel replaces 0 only", async () => {
    const { container, rerender } = render(Component, { props: { ...props, modelValue: 0, zeroLabel: "Immediately" } });
    expect(output(container)).toBe("Immediately");
    await rerender({ modelValue: 60 });
    expect(output(container)).toBe("1 min.");
  });
});
