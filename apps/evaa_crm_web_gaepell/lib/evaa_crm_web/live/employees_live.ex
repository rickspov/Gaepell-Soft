defmodule EvaaCrmWebGaepell.UsersLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{User, Specialist}
  import Ecto.Query
  alias Bcrypt

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    
    # Load users with preloaded specialist data
    users = EvaaCrmGaepell.Repo.all(
      from u in User,
      left_join: s in Specialist, on: u.specialist_id == s.id,
      preload: [specialist: s],
      order_by: [desc: u.inserted_at]
    )
    
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Usuarios")
     |> assign(:users, users)
     |> assign(:show_user_modal, false)
     |> assign(:editing_user, nil)
     |> assign(:specialist_data, %{})
     |> assign(:credentials_data, %{})
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)
    }
  end

  def handle_event("show_user_modal", %{"user_id" => user_id}, socket) do
    {user, specialist_data, credentials_data} = if user_id == "new" do
      # New user
      {%User{}, %{}, %{}}
    else
      # Existing user - load with preloaded specialist data
      user = EvaaCrmGaepell.Repo.one(
        from u in User,
        left_join: s in Specialist, on: u.specialist_id == s.id,
        preload: [specialist: s],
        where: u.id == ^user_id
      )
      
      specialist_data = if user && user.specialist, do: user.specialist, else: %{}
      credentials_data = %{} # Placeholder for future credentials implementation
      {user, specialist_data, credentials_data}
    end
    
    {:noreply, 
     socket
     |> assign(:show_user_modal, true)
     |> assign(:editing_user, user)
     |> assign(:specialist_data, specialist_data)
     |> assign(:credentials_data, credentials_data)}
  end

  def handle_event("hide_user_modal", _params, socket) do
    {:noreply, socket |> assign(:show_user_modal, false) |> assign(:editing_user, nil) |> assign(:specialist_data, %{}) |> assign(:credentials_data, %{})}
  end

  def handle_event("show_delete_confirm", %{"user_id" => user_id}, socket) do
    # Get user with preloaded specialist data
    user = EvaaCrmGaepell.Repo.one(
      from u in User,
      left_join: s in Specialist, on: u.specialist_id == s.id,
      preload: [specialist: s],
      where: u.id == ^user_id
    )
    
    if user do
      {:noreply, 
       socket
       |> assign(:show_delete_confirm, true)
       |> assign(:delete_target, %{id: user_id, email: user.email, name: get_user_display_name(user)})}
    else
      {:noreply, socket |> put_flash(:error, "Usuario no encontrado")}
    end
  end

  def handle_event("hide_delete_confirm", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_delete_confirm, false)
     |> assign(:delete_target, nil)}
  end

  def handle_event("confirm_delete_user", _params, socket) do
    case socket.assigns.delete_target do
      %{id: user_id} ->
        user = EvaaCrmGaepell.Repo.get(User, user_id)
        if user do
          case EvaaCrmGaepell.Repo.delete(user) do
            {:ok, _} ->
              # Reload users after deletion
              users = EvaaCrmGaepell.Repo.all(
                from u in User,
                left_join: s in Specialist, on: u.specialist_id == s.id,
                preload: [specialist: s],
                order_by: [desc: u.inserted_at]
              )
              
              {:noreply, 
               socket
               |> put_flash(:info, "Usuario eliminado exitosamente")
               |> assign(:show_delete_confirm, false)
               |> assign(:delete_target, nil)
               |> assign(:users, users)}
            
            {:error, _} ->
              {:noreply, 
               socket
               |> put_flash(:error, "Error al eliminar el usuario")
               |> assign(:show_delete_confirm, false)
               |> assign(:delete_target, nil)}
          end
        else
          {:noreply, 
           socket
           |> put_flash(:error, "Usuario no encontrado")
           |> assign(:show_delete_confirm, false)
           |> assign(:delete_target, nil)}
        end
      
      _ ->
        {:noreply, 
         socket
         |> put_flash(:error, "Error: Usuario no especificado")
         |> assign(:show_delete_confirm, false)
         |> assign(:delete_target, nil)}
    end
  end

  def handle_event("save_user", %{"user" => user_params, "specialist" => specialist_params, "credentials" => credentials_params}, socket) do
    # Add business_id for demo purposes
    user_params = Map.put(user_params, "business_id", 1)
    
    # Handle password hashing
    user_params = if user_params["password"] && user_params["password"] != "" do
      Map.put(user_params, "password_hash", Bcrypt.hash_pwd_salt(user_params["password"]))
      |> Map.delete("password")
    else
      Map.delete(user_params, "password")
    end
    
    case save_user_with_specialist(socket.assigns.editing_user, user_params, specialist_params, credentials_params) do
      {:ok, _user} ->
        # Reload users after successful save
        users = EvaaCrmGaepell.Repo.all(
          from u in User,
          left_join: s in Specialist, on: u.specialist_id == s.id,
          preload: [specialist: s],
          order_by: [desc: u.inserted_at]
        )
        
        {:noreply, 
         socket
         |> put_flash(:info, "Usuario guardado exitosamente")
         |> assign(:show_user_modal, false)
         |> assign(:editing_user, nil)
         |> assign(:specialist_data, %{})
         |> assign(:credentials_data, %{})
         |> assign(:users, users)}
      
      {:error, changeset} ->
        {:noreply, 
         socket
         |> assign(:editing_user, %{socket.assigns.editing_user | action: :insert, errors: changeset.errors})
         |> put_flash(:error, "Error al guardar el usuario: #{inspect(changeset.errors)}")}
    end
  end

  def handle_event("save_user", %{"user" => user_params}, socket) do
    # Handle case when no specialist or credentials data is provided
    handle_event("save_user", %{"user" => user_params, "specialist" => %{}, "credentials" => %{}}, socket)
  end

  def handle_event("change_role", %{"user" => %{"role" => role}}, socket) do
    updated_user = Map.put(socket.assigns.editing_user, :role, role)
    {:noreply, assign(socket, :editing_user, updated_user)}
  end

  defp save_user_with_specialist(user, user_params, specialist_params, _credentials_params) do
    EvaaCrmGaepell.Repo.transaction(fn ->
      # Save user first
      user_result = save_user(user, user_params)
      
      case user_result do
        {:ok, saved_user} ->
          # If role is specialist, create/update specialist
          if user_params["role"] == "specialist" do
            
            # Handle checkbox for is_active
            is_active = Map.get(specialist_params, "is_active") == "true"
            
            # Generate default names if not provided
            first_name = specialist_params["first_name"] || "Especialista"
            last_name = specialist_params["last_name"] || "Usuario"
            specialization = specialist_params["specialization"] || "Otra"
            
            specialist_attrs = Map.merge(specialist_params, %{
              "business_id" => 1,
              "status" => specialist_params["status"] || "active",
              "is_active" => is_active,
              "email" => user_params["email"], # Use the same email as the user
              "first_name" => first_name,
              "last_name" => last_name,
              "specialization" => specialization
            })
            
            # Check if user already has a specialist
            if saved_user.specialist_id do
              # Update existing specialist
              specialist = EvaaCrmGaepell.Repo.get(Specialist, saved_user.specialist_id)
              case update_specialist(specialist, specialist_attrs) do
                {:ok, _specialist} -> saved_user
                {:error, changeset} -> EvaaCrmGaepell.Repo.rollback(changeset)
              end
            else
                          # Create new specialist
            case create_specialist(specialist_attrs) do
              {:ok, specialist} ->
                # Update user with specialist_id
                case update_user_specialist_id(saved_user, specialist.id) do
                  {:ok, _user} -> saved_user
                  {:error, changeset} -> EvaaCrmGaepell.Repo.rollback(changeset)
                end
              {:error, changeset} -> 
                EvaaCrmGaepell.Repo.rollback(changeset)
            end
            end
          else
            saved_user
          end
        
        {:error, changeset} ->
          EvaaCrmGaepell.Repo.rollback(changeset)
      end
    end)
  end

  defp save_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> EvaaCrmGaepell.Repo.insert_or_update()
  end

  defp save_user(nil, attrs) do
    %User{}
    |> User.changeset(attrs)
    |> EvaaCrmGaepell.Repo.insert()
  end

  defp update_user_specialist_id(user, specialist_id) do
    user
    |> User.changeset(%{specialist_id: specialist_id})
    |> EvaaCrmGaepell.Repo.update()
  end

  defp create_specialist(attrs) do
    %Specialist{}
    |> Specialist.changeset(attrs)
    |> EvaaCrmGaepell.Repo.insert()
  end

  defp update_specialist(%Specialist{} = specialist, attrs) do
    specialist
    |> Specialist.changeset(attrs)
    |> EvaaCrmGaepell.Repo.update()
  end

  defp get_user_display_name(user) do
    cond do
      user.specialist && user.specialist.first_name && user.specialist.last_name ->
        "#{user.specialist.first_name} #{user.specialist.last_name}"
      user.specialist && user.specialist.first_name ->
        user.specialist.first_name
      user.specialist && user.specialist.last_name ->
        user.specialist.last_name
      true ->
        user.email
    end
  end

  defp get_role_label(role) do
    case role do
      "admin" -> "Administrador"
      "specialist" -> "Especialista"
      "employee" -> "Empleado"
      "manager" -> "Recepcionista"
      _ -> role
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex items-center mb-6">
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Usuarios</h1>
        <button class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded ml-4" phx-click="show_user_modal" phx-value-user_id="new">
          Añadir Usuario
        </button>
      </div>
      <div class="bg-white dark:bg-gray-800 shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">Listado de Usuarios</h3>
        </div>
        <div class="p-6">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead>
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Usuario</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Email</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Rol</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Especialización</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Estado</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Acciones</th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              <%= for user <- @users do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div class="flex-shrink-0 h-10 w-10">
                        <div class="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                          <span class="text-sm font-medium text-blue-600 dark:text-blue-300">
                            <%= String.first(get_user_display_name(user)) %>
                          </span>
                        </div>
                      </div>
                      <div class="ml-4">
                        <div class="text-sm font-medium text-gray-900 dark:text-white">
                          <%= get_user_display_name(user) %>
                        </div>
                        <%= if user.specialist do %>
                          <div class="text-sm text-gray-500 dark:text-gray-400">
                            ID: <%= user.specialist.id %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    <%= user.email %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={[
                      "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                      case user.role do
                        "admin" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                        "specialist" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
                        "employee" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                        "manager" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
                        _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
                      end
                    ]}>
                      <%= get_role_label(user.role) %>
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    <%= if user.specialist, do: user.specialist.specialization, else: "-" %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <%= if user.specialist do %>
                      <span class={[
                        "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                        case user.specialist.status do
                          "active" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                          "inactive" -> "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
                          "vacation" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
                          _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
                        end
                      ]}>
                        <%= case user.specialist.status do
                          "active" -> "Activo"
                          "inactive" -> "Inactivo"
                          "vacation" -> "Vacaciones"
                          _ -> user.specialist.status
                        end %>
                      </span>
                    <% else %>
                      <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200">
                        Sin especialista
                      </span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div class="flex space-x-2">
                      <button 
                        phx-click="show_user_modal" 
                        phx-value-user_id={user.id}
                        class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 p-1"
                        title="Editar usuario">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                        </svg>
                      </button>
                      <%= if user.specialist do %>
                        <a 
                          href={"/especialistas/#{user.specialist.id}"} 
                          class="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300 p-1"
                          title="Ver perfil de especialista">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                          </svg>
                        </a>
                      <% end %>
                      <button 
                        phx-click="show_delete_confirm" 
                        phx-value-user_id={user.id}
                        class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 p-1"
                        title="Eliminar usuario">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <%= if @show_user_modal do %>
        <div class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg w-full max-w-2xl p-8 relative">
            <button class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300" phx-click="hide_user_modal">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
            <h2 class="text-2xl font-bold mb-4 text-gray-900 dark:text-white"><%= if @editing_user && @editing_user.id, do: "Editar Usuario", else: "Nuevo Usuario" %></h2>
            <form phx-submit="save_user">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email *</label>
                  <input 
                    type="email" 
                    name="user[email]" 
                    value={@editing_user.email || ""} 
                    required 
                    class={
                      "w-full px-3 py-2 border rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent " <> 
                      (if Map.get(@editing_user, :errors) && Map.get(@editing_user.errors, :email), do: "border-red-500", else: "border-gray-300 dark:border-gray-600")
                    } />
                  <%= if Map.get(@editing_user, :errors) && Map.get(@editing_user.errors, :email) do %>
                    <p class="text-red-500 text-xs mt-1"><%= elem(@editing_user.errors[:email], 0) %></p>
                  <% end %>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Contraseña 
                    <span class="text-xs text-gray-400">
                      <%= if @editing_user.id, do: "(dejar vacío para no cambiar)", else: "(mínimo 6 caracteres)" %>
                    </span>
                  </label>
                  <input 
                    type="password" 
                    name="user[password]" 
                    minlength="6"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Rol *</label>
                  <select 
                    name="user[role]" 
                    required
                    phx-change="change_role"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="">Seleccionar rol</option>
                    <option value="specialist" selected={@editing_user.role == "specialist"}>Especialista</option>
                    <option value="admin" selected={@editing_user.role == "admin"}>Administrador</option>
                    <option value="manager" selected={@editing_user.role == "manager"}>Recepcionista</option>
                  </select>
                </div>
              </div>
              <%= if Map.get(@editing_user, :role) == "specialist" do %>
                <div class="mt-6 border-t pt-4">
                  <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Datos de Especialista</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Nombre(s)</label>
                      <input 
                        type="text" 
                        name="specialist[first_name]" 
                        value={Map.get(@specialist_data, :first_name, "")} 
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Apellidos</label>
                      <input 
                        type="text" 
                        name="specialist[last_name]" 
                        value={Map.get(@specialist_data, :last_name, "")} 
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Especialidad</label>
                      <select 
                        name="specialist[specialization]"
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                        <option value="">Seleccionar especialidad</option>
                        <%= for option <- ["Masaje Terapéutico", "Facial", "Corporal", "Depilación", "Manicure/Pedicure", "Maquillaje", "Estética Dental", "Otra"] do %>
                          <option value={option} selected={Map.get(@specialist_data, :specialization, "") == option}><%= option %></option>
                        <% end %>
                      </select>
                    </div>
                  </div>
                </div>
                <div class="mt-6 border-t pt-4">
                  <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Información Adicional</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Teléfono</label>
                      <input 
                        type="tel" 
                        name="specialist[phone]" 
                        value={Map.get(@specialist_data, :phone, "")} 
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Estado</label>
                      <select 
                        name="specialist[status]"
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                        <option value="active" selected={Map.get(@specialist_data, :status, "active") == "active"}>Activo</option>
                        <option value="inactive" selected={Map.get(@specialist_data, :status, "") == "inactive"}>Inactivo</option>
                        <option value="vacation" selected={Map.get(@specialist_data, :status, "") == "vacation"}>Vacaciones</option>
                      </select>
                    </div>
                  </div>
                  <div class="mt-4">
                    <label class="flex items-center">
                      <input 
                        type="checkbox" 
                        name="specialist[is_active]" 
                        value="true"
                        checked={Map.get(@specialist_data, :is_active, true)}
                        class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50" />
                      <span class="ml-2 text-sm text-gray-700 dark:text-gray-300">Especialista activo</span>
                    </label>
                  </div>
                </div>
              <% end %>
              <div class="mt-8 flex justify-end space-x-3">
                <button type="button" phx-click="hide_user_modal" class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">Cancelar</button>
                <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700">Guardar</button>
              </div>
            </form>
          </div>
        </div>
      <% end %>

      <!-- Delete Confirmation Modal -->
      <%= if @show_delete_confirm do %>
        <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white dark:bg-gray-800">
            <div class="mt-3">
              <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                  Confirmar Eliminación
                </h3>
                <button 
                  phx-click="hide_delete_confirm"
                  class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                  </svg>
                </button>
              </div>

              <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-red-600 dark:text-red-400 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
                  </svg>
                  <span class="text-red-800 dark:text-red-200 font-medium">¿Estás seguro?</span>
                </div>
                <p class="text-red-700 dark:text-red-300 text-sm mt-1">
                  Estás a punto de eliminar al usuario <strong><%= @delete_target.name %></strong> (<%= @delete_target.email %>).
                </p>
                <p class="text-red-700 dark:text-red-300 text-sm mt-2">
                  Esta acción no se puede deshacer y eliminará permanentemente todas las credenciales de acceso del usuario.
                </p>
              </div>

              <div class="flex justify-end space-x-3">
                <button 
                  type="button"
                  phx-click="hide_delete_confirm"
                  class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600">
                  Cancelar
                </button>
                <button 
                  type="button"
                  phx-click="confirm_delete_user"
                  class="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md hover:bg-red-700">
                  Eliminar Usuario
                </button>
              </div>
          </div>
        </div>
      </div>
      <% end %>
    </div>
    """
  end
end 