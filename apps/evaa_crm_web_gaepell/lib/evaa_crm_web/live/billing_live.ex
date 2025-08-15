defmodule EvaaCrmWebGaepell.BillingLive do
  use EvaaCrmWebGaepell, :live_view

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(page_title: "Billing")
    }
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Billing</h1>
        <button class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Nueva Factura
        </button>
      </div>
      
      <div class="bg-white dark:bg-gray-800 shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">Facturación</h3>
        </div>
        <div class="p-6">
          <div class="text-center text-gray-500 dark:text-gray-400 py-8">
            <p>No hay facturas emitidas</p>
            <p class="text-sm mt-2">Haz clic en "Nueva Factura" para crear una factura</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end 