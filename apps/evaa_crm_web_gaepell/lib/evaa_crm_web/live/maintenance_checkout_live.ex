defmodule EvaaCrmWebGaepell.MaintenanceCheckoutLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Repo, MaintenanceTicket, MaintenanceTicketCheckout}
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(EvaaCrmGaepell.User, user_id), else: nil
    tickets = list_open_tickets()
    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:tickets, tickets)
      |> assign(:selected_ticket, nil)
      |> assign(:checkout_changeset, MaintenanceTicketCheckout.changeset(%MaintenanceTicketCheckout{}, %{}))
      |> assign(:step, :list)
      |> allow_upload(:photos, accept: ~w(.jpg .jpeg .png), max_entries: 3)
      |> assign(:signature_data, nil)
    {:ok, socket}
  end

  defp list_open_tickets do
    Repo.all(from t in MaintenanceTicket, where: t.status != "checkout", order_by: [desc: t.inserted_at])
  end

  @impl true
  def handle_event("select_ticket", %{"ticket_id" => ticket_id}, socket) do
    ticket = Repo.get(MaintenanceTicket, ticket_id)
    {:noreply,
      socket
      |> assign(:selected_ticket, ticket)
      |> assign(:step, :form)
    }
  end

  @impl true
  def handle_event("guardar_checkout", %{"maintenance_ticket_checkout" => params}, socket) do
    params = Map.put(params, "maintenance_ticket_id", socket.assigns.selected_ticket.id)
    # Procesar fotos
    uploaded_files = consume_uploaded_entries(socket, :photos, fn %{path: path}, _entry ->
      dest = Path.join(["priv/static/uploads", Path.basename(path)])
      File.cp!(path, dest)
      ["/uploads/" <> Path.basename(dest)]
    end)
    photos = uploaded_files
    params = Map.put(params, "photos", photos)
    # Procesar firma
    signature = params["signature"] || socket.assigns.signature_data
    params = Map.put(params, "signature", signature)
    changeset = MaintenanceTicketCheckout.changeset(%MaintenanceTicketCheckout{}, params)
    # Validar firma obligatoria
    if is_nil(signature) or signature == "" do
      changeset = Ecto.Changeset.add_error(changeset, :signature, "La firma es obligatoria")
    end
    if changeset.valid? do
      Repo.insert!(changeset)
      ticket = socket.assigns.selected_ticket
      MaintenanceTicket.changeset(ticket, %{status: "check_out"}) |> Repo.update!()
      tickets = list_open_tickets()
      {:noreply,
        socket
        |> assign(:tickets, tickets)
        |> assign(:selected_ticket, nil)
        |> assign(:step, :list)
        |> put_flash(:info, "Checkout registrado exitosamente.")
      }
    else
      {:noreply, assign(socket, :checkout_changeset, changeset)}
    end
  end
  def handle_event("update_signature", %{"data" => data}, socket) do
    {:noreply, assign(socket, :signature_data, data)}
  end
end 