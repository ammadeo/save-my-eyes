import { describe, expect, test, vi } from "vitest";
import { fireEvent, render } from "@testing-library/vue";
import Component from "./BaseInputRange.vue";

vi.mock("@/bridge", () => ({}));

const props = {
  modelValue: 150,
  max: 60,
  min: 2,
  scale: 10,
  step: 1,
  suffix: "suffix-x",
  name: "name-x",
  forceLarge: true,
};
const displayValue = (value = props.modelValue, scale = props.scale) => Math.floor(value / scale).toString();

describe("components/brand/BaseInputRange.vue", () => {
  test("has suffix", () => {
    const { getByText } = render(Component, { props });
    expect(getByText(props.suffix)).toBeVisible();
  });

  test("both inputs have min, max, step and value", () => {
    const { getAllByDisplayValue } = render(Component, { props });
    const inputs = getAllByDisplayValue(displayValue());
    expect(inputs).toHaveLength(2);
    for (const input of inputs) {
      expect(input).toHaveAttribute("max", "60");
      expect(input).toHaveAttribute("min", "2");
      expect(input).toHaveAttribute("step", "1");
    }
  });

  test("number input sizes itself to the value", async () => {
    const { getAllByDisplayValue, rerender } = render(Component, { props });
    const input = getAllByDisplayValue(displayValue())[0];
    expect(input).toHaveClass("w-6");
    await rerender({ ...props, scale: 1 });
    expect(input).toHaveClass("w-8");
    await rerender({ ...props, scale: 50 });
    expect(input).toHaveClass("w-4");
  });

  test("shows min, max with suffix and the name", () => {
    const { getByText } = render(Component, { props });
    expect(getByText(`${props.min} ${props.suffix}`)).toBeVisible();
    expect(getByText(`${props.max} ${props.suffix}`)).toBeVisible();
    expect(getByText(props.name)).toBeVisible();
  });

  test.each([0, 1])("input %i emits the scaled value", async (index) => {
    const { getAllByDisplayValue, emitted } = render(Component, { props });
    const input = getAllByDisplayValue(displayValue())[index];
    await fireEvent.update(input, "20");
    expect(emitted()["update:modelValue"]).toEqual([[200]]);
  });

  test("warns outside the range and clears on blur", async () => {
    const { getAllByDisplayValue, findByText, queryByText, emitted } = render(Component, { props });
    const input = getAllByDisplayValue(displayValue())[0];
    await fireEvent.update(input, "61");
    expect(await findByText(`You can't set more than 60 ${props.suffix}`)).toBeVisible();
    await fireEvent.blur(input);
    expect(queryByText(`You can't set more than 60 ${props.suffix}`)).toBeNull();
    expect(emitted().blur).toHaveLength(1);
  });
});
