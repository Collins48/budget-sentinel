defmodule BudgetSentinelWeb.CoreComponents do
  use Phoenix.Component

  @doc "Renders flash notices for :info and :error kinds."
  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  attr :kind, :atom, values: [:info, :error]
  attr :flash, :map, default: %{}

  def flash(assigns) do
    msg = Phoenix.Flash.get(assigns.flash, assigns.kind)
    assigns = assign(assigns, :msg, msg)

    ~H"""
    <div :if={@msg} class={["flash", "flash--#{@kind}"]} phx-click={Phoenix.LiveView.JS.hide()} role="alert">
      <%= @msg %>
    </div>
    """
  end

  @doc "Page/section header with optional subtitle and actions slot."
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={["auth-header", @class]}>
      <h1><%= render_slot(@inner_block) %></h1>
      <p :if={@subtitle != []} class="auth-header__subtitle"><%= render_slot(@subtitle) %></p>
      <div :if={@actions != []} class="auth-header__actions"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc "A simple form wrapper styled to match the app's form fields."
  attr :for, :any, required: true
  attr :as, :any, default: nil
  attr :rest, :global, include: ~w(action phx-submit phx-change phx-update method)
  slot :inner_block, required: true
  slot :actions

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <%= render_slot(@inner_block, f) %>
      <div :for={action <- @actions} class="modal-actions"><%= render_slot(action, f) %></div>
    </.form>
    """
  end

  @doc "A labeled form input bound to a `Phoenix.HTML.FormField`."
  attr :field, Phoenix.HTML.FormField
  attr :type, :string, default: "text"
  attr :label, :string, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :rest, :global, include: ~w(type placeholder required autocomplete)

  def input(%{field: field} = assigns) do
    errors = Enum.map(field.errors, &translate_error/1)

    assigns =
      assigns
      |> assign(:id, assigns.id || field.id)
      |> assign(:name, assigns.name || field.name)
      |> assign(:value, if(assigns.value, do: assigns.value, else: field.value))
      |> assign(:errors, errors)

    ~H"""
    <div class="form-field">
      <label :if={@label}><%= @label %></label>
      <input :if={@type != "checkbox"} type={@type} id={@id} name={@name} value={@value} {@rest} />
      <input
        :if={@type == "checkbox"}
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@value in [true, "true"]}
        {@rest}
      />
      <p :for={msg <- @errors} class="form-error"><%= msg %></p>
    </div>
    """
  end

  defp translate_error({msg, _opts}), do: msg

  @doc "Primary submit button, styled like the rest of the app's buttons."
  attr :type, :string, default: "submit"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(phx-disable-with disabled form)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class={["btn", @class]} {@rest}><%= render_slot(@inner_block) %></button>
    """
  end

  @doc "Generic error banner shown above a form when the changeset is invalid."
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="flash flash--error"><%= render_slot(@inner_block) %></p>
    """
  end

  @doc "Color-weighted badge for an anomaly's risk severity."
  attr :severity, :string, required: true
  attr :risk_score, :any, default: nil

  def risk_badge(assigns) do
    ~H"""
    <span class={["risk-badge", "risk-badge--#{@severity}"]}>
      <%= String.upcase(@severity) %>
      <%= if @risk_score do %>
        <span class="risk-badge__score"><%= Decimal.to_string(@risk_score) %></span>
      <% end %>
    </span>
    """
  end

  @doc "Small stat card used on the dashboard overview row."
  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :accent, :string, default: "primary"

  def stat_card(assigns) do
    ~H"""
    <div class={["stat-card", "stat-card--#{@accent}"]}>
      <p class="stat-card__label"><%= @label %></p>
      <p class="stat-card__value"><%= @value %></p>
    </div>
    """
  end

  @doc "Horizontal progress bar showing budget utilization, capped visually at 100%."
  attr :percent, :any, required: true

  def budget_bar(assigns) do
    numeric = to_number(assigns.percent)
    assigns = assign(assigns, :clamped, min(numeric, 100.0))
    assigns = assign(assigns, :over_budget, numeric > 100.0)
    assigns = assign(assigns, :numeric, numeric)

    ~H"""
    <div class="budget-bar">
      <div class={["budget-bar__fill", @over_budget && "budget-bar__fill--over"]} style={"width: #{@clamped}%"}>
      </div>
      <span class="budget-bar__label"><%= :erlang.float_to_binary(@numeric, decimals: 1) %>%</span>
    </div>
    """
  end

  @doc "Fraud-type label rendered in human-readable form, e.g. ghost_project -> Ghost Project."
  attr :fraud_type, :string, required: true

  def fraud_type_label(assigns) do
    ~H"""
    <span class="fraud-type-label"><%= humanize(@fraud_type) %></span>
    """
  end

  defp humanize(value) do
    value
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp to_number(%Decimal{} = decimal), do: Decimal.to_float(decimal)
  defp to_number(value) when is_number(value), do: value * 1.0
  defp to_number(value) when is_binary(value), do: String.to_float(value)
end
