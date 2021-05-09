defmodule Scenic.Driver.Rpi.ADS7846.MouseTest do
  use ExUnit.Case, async: true

  alias Scenic.Driver.Rpi.ADS7846.Mouse

  @device "ADS7846 Touchscreen"
  @initial_state %{
    device: @device,
    event_path: nil,
    event_pid: nil,
    viewport: nil,
    slot: 0,
    touch: false,
    mouse_x: nil,
    mouse_y: nil,
    mouse_event: nil,
    calibration: nil,
    rotate: 0,
    size: nil
  }

  setup %{touch: touch, mouse_x: x, mouse_y: y} do
    state = %{@initial_state | touch: touch, mouse_x: x, mouse_y: y}

    [state: state]
  end

  describe "when touch is false" do
    @describetag touch: false

    @tag mouse_x: nil, mouse_y: nil
    test "and button pressed without mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 1}, {:ev_abs, :abs_x, 12}, {:ev_abs, :abs_y, 34}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_button, {:left, :press, 0, {12, 34}}}
      assert %{touch: true, mouse_x: 12, mouse_y: 34} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: 1, mouse_y: 2
    test "and button pressed with mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 1}, {:ev_abs, :abs_x, 12}, {:ev_abs, :abs_y, 34}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_button, {:left, :press, 0, {12, 34}}}
      assert %{touch: true, mouse_x: 12, mouse_y: 34} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: nil, mouse_y: nil
    test "and button released without mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 0}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == :no_input_event
      assert %{touch: false, mouse_x: nil, mouse_y: nil} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: 1, mouse_y: 2
    test "and button released with mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 0}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == :no_input_event
      assert %{touch: false, mouse_x: 1, mouse_y: 2} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: 1, mouse_y: 2
    test "and move", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_abs, :abs_x, 12}, {:ev_abs, :abs_y, 34}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_pos, {12, 34}}
      assert %{touch: false, mouse_x: 12, mouse_y: 34} = Mouse.update_state(mouse_event, state)
    end
  end

  describe "when touch is true" do
    @describetag touch: true

    @tag mouse_x: nil, mouse_y: nil
    test "and button pressed without mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 1}, {:ev_abs, :abs_x, 12}, {:ev_abs, :abs_y, 34}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_pos, {12, 34}}
      assert %{touch: true, mouse_x: 12, mouse_y: 34} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: 1, mouse_y: 3
    test "and button pressed with mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 1}, {:ev_abs, :abs_x, 12}, {:ev_abs, :abs_y, 34}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_pos, {12, 34}}
      assert %{touch: true, mouse_x: 12, mouse_y: 34} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: nil, mouse_y: nil
    test "and button released without mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 0}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_button, {:left, :release, 0, {nil, nil}}}
      assert %{touch: false, mouse_x: nil, mouse_y: nil} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: 1, mouse_y: 2
    test "and button released with mouse point", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_key, :btn_touch, 0}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_button, {:left, :release, 0, {1, 2}}}
      assert %{touch: false, mouse_x: nil, mouse_y: nil} = Mouse.update_state(mouse_event, state)
    end

    @tag mouse_x: 1, mouse_y: 2
    test "and move", %{state: state} do
      mouse_event =
        state
        |> Mouse.new()
        |> Mouse.simulate([{:ev_abs, :abs_x, 12}, {:ev_abs, :abs_y, 34}])

      input_event =
        mouse_event
        |> Mouse.get_input_event()

      assert input_event == {:cursor_pos, {12, 34}}
      assert %{touch: true, mouse_x: 12, mouse_y: 34} = Mouse.update_state(mouse_event, state)
    end
  end
end
