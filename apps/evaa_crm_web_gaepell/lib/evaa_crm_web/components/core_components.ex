defmodule EvaaCrmWebGaepell.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: EvaaCrmWebGaepell.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)
  attr :input_class, :string, default: nil, doc: "additional CSS classes for the input element"

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={[
            "rounded border-zinc-300 text-zinc-900 focus:ring-0",
            @input_class
          ]}
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm",
          @input_class
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400",
          @input_class
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400",
          @input_class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800 dark:text-white">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(EvaaCrmWebGaepell.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(EvaaCrmWebGaepell.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  def ticket_profile_modal(assigns) do
    ~H"""
    <%= if @show_ticket_profile and @selected_ticket do %>
      <div class="fixed inset-0 bg-black/70 dark:bg-black/80 flex items-center justify-center z-50" 
           phx-click="hide_ticket_profile" phx-window-keydown="hide_ticket_profile" phx-key="escape" phx-capture-click>
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col border border-gray-200 dark:border-gray-700 relative overflow-y-auto" phx-click="ignore">
          
          <!-- Header -->
          <div class="flex items-center gap-3 p-6 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-blue-100/60 via-white/80 to-green-100/60 dark:from-blue-900/20 dark:via-gray-800 dark:to-green-900/20 rounded-t-2xl">
            <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-blue-500/90 text-white shadow-lg">
              <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
              </svg>
            </span>
            <div class="flex-1">
              <h3 class="text-2xl font-bold text-gray-900 dark:text-gray-100 leading-tight">
                Ticket #<%= @selected_ticket.id %> - <%= @selected_ticket.title %>
              </h3>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                <%= @selected_ticket.truck.brand %> <%= @selected_ticket.truck.model %> (<%= @selected_ticket.truck.license_plate %>)
              </p>
            </div>
            <button phx-click="hide_ticket_profile" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 text-2xl font-bold">&times;</button>
          </div>

          <!-- Content -->
          <div class="p-6">
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              
              <!-- Ticket Details -->
              <div class="space-y-6">
                <div>
                  <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Información del Ticket</h4>
                  <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 space-y-3">
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Estado:</span>
                      <span class={"px-2 py-1 text-xs font-semibold rounded-full " <> status_color(@selected_ticket.status)}>
                        <%= case @selected_ticket.status do
                          "check_in" -> "Check In"
                          "in_workshop" -> "En Taller/Reparación"
                          "final_review" -> "Revisión Final"
                          "car_wash" -> "Car Wash"
                          "check_out" -> "Check Out"
                          "cancelled" -> "Cancelado"
                          _ -> @selected_ticket.status
                        end %>
                      </span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Prioridad:</span>
                      <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.priority %></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Fecha de Ingreso:</span>
                      <span class="text-sm text-gray-900 dark:text-white">
                        <%= if @selected_ticket.entry_date do %>
                          <%= Calendar.strftime(@selected_ticket.entry_date, "%d/%m/%Y %H:%M") %>
                        <% else %>
                          No especificada
                        <% end %>
                      </span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Kilometraje:</span>
                      <span class="text-sm text-gray-900 dark:text-white">
                        <%= if @selected_ticket.mileage, do: "#{@selected_ticket.mileage} km", else: "No especificado" %>
                      </span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Combustible:</span>
                      <span class="text-sm text-gray-900 dark:text-white">
                        <%= @selected_ticket.fuel_level || "No especificado" %>
                      </span>
                    </div>
                    <%= if @selected_ticket.visible_damage do %>
                      <div class="flex justify-between">
                        <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Daños Visibles:</span>
                        <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.visible_damage %></span>
                      </div>
                    <% end %>
                    <%= if @selected_ticket.exit_notes do %>
                      <div class="flex justify-between">
                        <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Notas de Salida:</span>
                        <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.exit_notes %></span>
                      </div>
                    <% end %>
                  </div>
                </div>

                <!-- Deliverer Information -->
                <%= if @selected_ticket.deliverer_name do %>
                  <div>
                    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                      <svg class="w-5 h-5 mr-2 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
                      </svg>
                      Información del Entregador
                    </h4>
                    <div class="bg-red-50 dark:bg-red-900/20 rounded-lg p-4 space-y-3 border-l-4 border-red-500">
                      <div class="flex justify-between">
                        <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Nombre:</span>
                        <span class="text-sm font-semibold text-gray-900 dark:text-white"><%= @selected_ticket.deliverer_name %></span>
                      </div>
                      <%= if @selected_ticket.document_type && @selected_ticket.document_number do %>
                        <div class="flex justify-between">
                          <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Documento:</span>
                          <span class="text-sm text-gray-900 dark:text-white">
                            <%= case @selected_ticket.document_type do
                              "dni" -> "DNI"
                              "pasaporte" -> "Pasaporte"
                              "licencia" -> "Licencia"
                              "ruc" -> "RUC"
                              _ -> @selected_ticket.document_type
                            end %> <%= @selected_ticket.document_number %>
                          </span>
                        </div>
                      <% end %>
                      <%= if @selected_ticket.deliverer_phone do %>
                        <div class="flex justify-between">
                          <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Teléfono:</span>
                          <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.deliverer_phone %></span>
                        </div>
                      <% end %>

                      <%= if @selected_ticket.company_name do %>
                        <div class="flex justify-between">
                          <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Empresa:</span>
                          <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.company_name %></span>
                        </div>
                      <% end %>
                      <%= if @selected_ticket.position do %>
                        <div class="flex justify-between">
                          <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Cargo:</span>
                          <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.position %></span>
                        </div>
                      <% end %>
                      <%= if @selected_ticket.employee_number do %>
                        <div class="flex justify-between">
                          <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Número de Empleado:</span>
                          <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.employee_number %></span>
                        </div>
                      <% end %>
                      <%= if @selected_ticket.authorization_type do %>
                        <div class="flex justify-between">
                          <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Autorización:</span>
                          <span class="text-sm text-gray-900 dark:text-white">
                            <%= case @selected_ticket.authorization_type do
                              "propietario" -> "Propietario del vehículo/artículo"
                              "representante" -> "Representante autorizado"
                              "empleado" -> "Empleado de la empresa"
                              "conductor" -> "Conductor asignado"
                              _ -> @selected_ticket.authorization_type
                            end %>
                          </span>
                        </div>
                      <% end %>
                      <%= if @selected_ticket.special_conditions do %>
                        <div class="mt-3 pt-3 border-t border-red-200 dark:border-red-800">
                          <div class="flex justify-between">
                            <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Condiciones Especiales:</span>
                          </div>
                          <div class="mt-1 text-sm text-gray-900 dark:text-white bg-white dark:bg-gray-800 rounded p-2 border border-red-200 dark:border-red-800">
                            <%= @selected_ticket.special_conditions %>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <!-- Truck Details -->
                <div>
                  <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Información del Camión</h4>
                  <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 space-y-3">
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Marca/Modelo:</span>
                      <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.truck.brand %> <%= @selected_ticket.truck.model %></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Placa:</span>
                      <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.truck.license_plate %></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Año:</span>
                      <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.truck.year %></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Capacidad:</span>
                      <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.truck.capacity || "No especificada" %></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Tipo de Combustible:</span>
                      <span class="text-sm text-gray-900 dark:text-white"><%= @selected_ticket.truck.fuel_type || "No especificado" %></span>
                    </div>
                  </div>
                </div>

                <!-- Checkout Information -->
                <%= if @ticket_checkouts && length(@ticket_checkouts) > 0 do %>
                  <div>
                    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Entrega registrada</h4>
                    <%= for checkout <- Enum.take(@ticket_checkouts, 1) do %>
                      <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
                        <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-2">
                          <div>
                            <span class="font-semibold text-blue-700 dark:text-blue-300">Entregado a:</span> 
                            <span class="text-gray-900 dark:text-white"><%= checkout.delivered_to_name %></span>
                            <%= if checkout.delivered_to_id_number do %>
                              <span class="ml-2 text-xs text-gray-500">(<%= checkout.delivered_to_id_number %>)</span>
                            <% end %>
                          </div>
                          <div class="text-xs text-gray-400 mt-1 md:mt-0">
                            Fecha: <%= Calendar.strftime(checkout.delivered_at, "%d/%m/%Y %H:%M") %>
                          </div>
                        </div>
                        <%= if checkout.delivered_to_phone do %>
                          <div class="text-sm text-gray-700 dark:text-gray-200 mb-2">
                            Teléfono: <%= checkout.delivered_to_phone %>
                          </div>
                        <% end %>
                        <%= if checkout.notes && checkout.notes != "" do %>
                          <div class="text-xs text-gray-600 dark:text-gray-300 mb-2">
                            Notas: <%= checkout.notes %>
                          </div>
                        <% end %>
                        <%= if checkout.photos && length(checkout.photos) > 0 do %>
                          <div class="mb-2">
                            <span class="text-xs font-medium text-gray-700 dark:text-gray-300">Fotos de entrega:</span>
                            <div class="flex gap-2 mt-1">
                              <%= for photo <- checkout.photos do %>
                                <img src={photo} class="w-16 h-16 object-cover rounded border" alt="Foto de entrega" />
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                        <%= if checkout.signature do %>
                          <div class="mt-2">
                            <span class="text-xs font-medium text-gray-700 dark:text-gray-300">Firma de entrega:</span>
                            <div class="mt-1">
                              <img src={checkout.signature} alt="Firma de entrega" class="h-16 bg-white border rounded" />
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>

                <!-- Photos -->
                <%= if @selected_ticket.damage_photos && length(@selected_ticket.damage_photos) > 0 do %>
                  <div>
                    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Fotos del Daño</h4>
                    <div class="grid grid-cols-2 gap-2">
                      <%= for photo_url <- @selected_ticket.damage_photos do %>
                        <img src={photo_url} alt="Foto del daño" class="w-full h-32 object-cover rounded-lg border border-gray-200 dark:border-gray-600" />
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <!-- Digital Signature -->
                <%= if @selected_ticket.signature_url do %>
                  <div>
                    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Firma Digital</h4>
                    <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                      <img src={@selected_ticket.signature_url} alt="Firma digital" class="w-full max-w-md mx-auto border border-gray-300 dark:border-gray-600 rounded-lg bg-white" />
                      <p class="text-xs text-gray-500 dark:text-gray-400 text-center mt-2">Firma capturada durante el check-in</p>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- Activity Logs -->
              <div>
                <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Historial de Actividad</h4>
                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 max-h-96 overflow-y-auto">
                  <%= if Enum.empty?(@ticket_logs) do %>
                    <div class="text-center py-8">
                      <svg class="mx-auto h-8 w-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                      </svg>
                      <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">Sin actividad registrada</p>
                    </div>
                  <% else %>
                    <div class="space-y-4">
                      <%= for log <- @ticket_logs do %>
                        <div class="flex items-start space-x-3">
                          <div class="flex-shrink-0">
                            <div class="w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                              <svg class="w-4 h-4 text-blue-600 dark:text-blue-300" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 12a5 5 0 110-10 5 5 0 010 10zm0-2a3 3 0 100-6 3 3 0 000 6zm9 11a1 1 0 01-2 0v-2a3 3 0 00-3-3H8a3 3 0 00-3 3v2a1 1 0 11-2 0v-2a5 5 0 015-5h8a5 5 0 015 5v2z"/>
                              </svg>
                            </div>
                          </div>
                          <div class="flex-1 min-w-0">
                            <div class="text-sm text-gray-900 dark:text-white">
                              <%= if log.user do %>
                                <span class="font-semibold text-blue-600 dark:text-blue-500">
                                  <%= log.user.email %>
                                </span>
                              <% else %>
                                <span class="font-semibold text-gray-600 dark:text-gray-400">Usuario desconocido</span>
                              <% end %>
                              <%= log.description %>
                            </div>
                            <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                              <%= format_relative_time(log.inserted_at) %>
                            </div>
                            <%= if log.old_values && log.new_values do %>
                              <div class="mt-2 text-xs bg-gray-100 dark:bg-gray-600 rounded p-2">
                                <div class="font-medium text-gray-700 dark:text-gray-300 mb-1">Cambios:</div>
                                <%= for {key, old_value} <- log.old_values do %>
                                  <%= if Map.get(log.new_values, key) && Map.get(log.new_values, key) != old_value do %>
                                    <div class="text-gray-600 dark:text-gray-400">
                                      <span class="font-medium"><%= key %>:</span>
                                      <span class="line-through text-red-500"><%= old_value %></span>
                                      <span class="text-green-600">→</span>
                                      <span class="text-green-500"><%= Map.get(log.new_values, key) %></span>
                                    </div>
                                  <% end %>
                                <% end %>
                              </div>
                            <% end %>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer -->
          <div class="flex justify-end gap-3 p-6 border-t border-gray-200 dark:border-gray-700">
            <button phx-click="hide_ticket_profile" 
                    class="px-4 py-2 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700">
              Cerrar
            </button>
            <button phx-click="edit_ticket_from_profile" phx-value-ticket_id={@selected_ticket.id}
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
              Editar Ticket
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp status_color(status) do
    case status do
      "check_in" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      "in_workshop" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "final_review" -> "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
      "car_wash" -> "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
      "check_out" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "cancelled" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    # Convertir NaiveDateTime a DateTime para poder hacer la comparación
    datetime_with_zone = DateTime.from_naive!(datetime, "Etc/UTC")
    diff = DateTime.diff(now, datetime_with_zone, :second)
    
    cond do
      diff < 60 -> "hace un momento"
      diff < 3600 -> "hace #{div(diff, 60)} minutos"
      diff < 86400 -> "hace #{div(diff, 3600)} horas"
      diff < 2592000 -> "hace #{div(diff, 86400)} días"
      true -> Calendar.strftime(datetime, "%d/%m/%Y %H:%M")
    end
  end
end
