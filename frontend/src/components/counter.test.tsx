import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { Counter } from "./counter";

describe("Counter", () => {
  it("increments the count when the button is clicked", async () => {
    const user = userEvent.setup();

    render(<Counter />);

    expect(screen.getByText("Count: 0")).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Increment" }));

    expect(screen.getByText("Count: 1")).toBeInTheDocument();
  });
});
