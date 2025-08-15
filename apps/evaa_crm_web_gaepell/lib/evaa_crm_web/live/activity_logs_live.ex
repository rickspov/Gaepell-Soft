defmodule EvaaCrmWebGaepell.ActivityLogsLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{ActivityLog, Repo}
  import Ecto.Query

  @impl true
  def mount(%{"entity_type" => entity_type, "entity_id" => entity_id}, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    
    logs = ActivityLog.get_logs_for_entity(entity_type, String.to_integer(entity_id))
    
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Historial de Actividad")
     |> assign(:entity_type, entity_type)
     |> assign(:entity_id, entity_id)
     |> assign(:logs, logs)
     |> assign(:show_comment_form, false)
     |> assign(:new_comment, "")}
  end

  @impl true
  def handle_event("add_comment", %{"comment" => comment}, socket) do
    case ActivityLog.log_comment(
      socket.assigns.entity_type,
      socket.assigns.entity_id,
      comment,
      socket.assigns.current_user.id,
      socket.assigns.current_user.business_id
    ) do
      {:ok, _log} ->
        logs = ActivityLog.get_logs_for_entity(socket.assigns.entity_type, socket.assigns.entity_id)
        {:noreply, 
         socket
         |> assign(:logs, logs)
         |> assign(:show_comment_form, false)
         |> assign(:new_comment, "")
         |> put_flash(:info, "Comentario agregado exitosamente")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al agregar comentario")}
    end
  end

  @impl true
  def handle_event("toggle_comment_form", _params, socket) do
    {:noreply, assign(socket, :show_comment_form, !socket.assigns.show_comment_form)}
  end

  @impl true
  def handle_event("update_comment", %{"comment" => comment}, socket) do
    {:noreply, assign(socket, :new_comment, comment)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
          Historial de Actividad
        </h1>
        <p class="text-gray-600 dark:text-gray-400">
          <%= ActivityLog.get_entity_name(@entity_type) %> #<%= @entity_id %>
        </p>
      </div>

      <!-- Botón para agregar comentario -->
      <div class="mb-6">
        <button 
          phx-click="toggle_comment_form"
          class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 dark:focus:ring-blue-800">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          Agregar Comentario
        </button>
      </div>

      <!-- Formulario de comentario -->
      <%= if @show_comment_form do %>
        <div class="mb-6 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
          <form phx-submit="add_comment">
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Comentario
              </label>
              <textarea 
                name="comment"
                value={@new_comment}
                phx-keyup="update_comment"
                phx-value-comment={@new_comment}
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Escribe tu comentario aquí..."></textarea>
            </div>
            <div class="flex justify-end space-x-2">
              <button 
                type="button"
                phx-click="toggle_comment_form"
                class="px-4 py-2 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-700">
                Cancelar
              </button>
              <button 
                type="submit"
                class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
                Agregar Comentario
              </button>
            </div>
          </form>
        </div>
      <% end %>

      <!-- Timeline de logs -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <div class="p-6">
          <%= if Enum.empty?(@logs) do %>
            <div class="text-center py-8">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">Sin actividad</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Aún no hay registros de actividad para este elemento.
              </p>
            </div>
          <% else %>
            <ol class="relative border-s border-gray-200 dark:border-gray-700">
              <%= for log <- @logs do %>
                <li class="mb-10 ms-6">
                  <span class="absolute flex items-center justify-center w-6 h-6 bg-blue-100 rounded-full -start-3 ring-8 ring-white dark:ring-gray-900 dark:bg-blue-900">
                    <%= if log.user && Map.get(log.user, :profile_photo) do %>
                      <img class="rounded-full shadow-lg w-6 h-6" src={Map.get(log.user, :profile_photo)} alt="User photo"/>
                    <% else %>
                      <svg class="w-3 h-3 text-blue-600 dark:text-blue-300" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 12a5 5 0 110-10 5 5 0 010 10zm0-2a3 3 0 100-6 3 3 0 000 6zm9 11a1 1 0 01-2 0v-2a3 3 0 00-3-3H8a3 3 0 00-3 3v2a1 1 0 11-2 0v-2a5 5 0 015-5h8a5 5 0 015 5v2z"/>
                      </svg>
                    <% end %>
                  </span>
                  <div class="items-center justify-between p-4 bg-white border border-gray-200 rounded-lg shadow-xs sm:flex dark:bg-gray-700 dark:border-gray-600">
                    <time class="mb-1 text-xs font-normal text-gray-400 sm:order-last sm:mb-0">
                      <%= format_relative_time(log.inserted_at) %>
                    </time>
                    <div class="text-sm font-normal text-gray-500 dark:text-gray-300">
                                             <%= if log.user do %>
                         <span class="font-semibold text-blue-600 dark:text-blue-500">
                           <%= log.user.email %>
                         </span>
                       <% else %>
                         <span class="font-semibold text-gray-600 dark:text-gray-400">Usuario desconocido</span>
                       <% end %>
                      <%= log.description %>
                    </div>
                  </div>
                  
                  <!-- Mostrar comentario si existe -->
                  <%= if log.action == "commented" && log.metadata && log.metadata["comment"] do %>
                    <div class="mt-2 ml-4 p-3 text-xs italic font-normal text-gray-500 border border-gray-200 rounded-lg bg-gray-50 dark:bg-gray-600 dark:border-gray-500 dark:text-gray-300">
                      <%= log.metadata["comment"] %>
                    </div>
                  <% end %>
                  
                  <!-- Mostrar cambios de valores si existen -->
                  <%= if log.old_values && log.new_values do %>
                    <div class="mt-2 ml-4 p-3 text-xs border border-gray-200 rounded-lg bg-gray-50 dark:bg-gray-600 dark:border-gray-500">
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
                </li>
              <% end %>
            </ol>
          <% end %>
        </div>
      </div>
    </div>
    """
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