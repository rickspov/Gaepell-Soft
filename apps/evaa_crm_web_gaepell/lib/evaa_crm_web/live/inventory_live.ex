defmodule EvaaCrmWebGaepell.InventoryLive do
  use EvaaCrmWebGaepell, :live_view

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: EvaaCrmGaepell.Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    {:ok, 
     socket
     |> assign(:current_user, current_user)
     |> assign(page_title: "Inventory")
    }
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex flex-col items-center justify-center min-h-[60vh]">
        <svg class="w-20 h-20 text-gray-300 dark:text-gray-600 mb-6" fill="none" stroke="currentColor" viewBox="0 0 48 48">
          <circle cx="24" cy="24" r="22" stroke-width="4" stroke-dasharray="6 6" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M16 24h16M24 16v16" />
        </svg>
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">Inventario</h1>
        <p class="text-lg text-gray-500 dark:text-gray-400 mb-4">Coming soon</p>
        <p class="text-sm text-gray-400">Este módulo está en desarrollo. Próximamente podrás gestionar tu inventario aquí.</p>
      </div>
    </div>
    """
  end
end 