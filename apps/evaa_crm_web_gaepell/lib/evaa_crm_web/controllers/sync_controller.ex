defmodule EvaaCrmWebGaepell.SyncController do
  use EvaaCrmWebGaepell, :controller
  alias EvaaCrmGaepell.{Repo, Quotation, QuotationOption, Lead, Activity, User}
  import Ecto.Query

  def sync(conn, %{"action" => action, "data" => data, "type" => type}) do
    user_id = get_session(conn, :user_id)
    
    case process_sync_action(action, type, data, user_id) do
      {:ok, result} ->
        json(conn, %{
          success: true,
          message: "Sincronización exitosa",
          data: result
        })
      
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: reason
        })
    end
  end

  def sync(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "Parámetros inválidos"
    })
  end

  # Procesar acciones de sincronización
  defp process_sync_action("create", "quotation", data, user_id) do
    quotation_attrs = %{
      quotation_number: generate_quotation_number(),
      client_name: data["client_name"],
      client_email: data["client_email"],
      client_phone: data["client_phone"],
      quantity: data["quantity"],
      special_requirements: data["special_requirements"],
      status: data["status"] || "draft",
      total_cost: parse_decimal(data["total_cost"]),
      markup_percentage: parse_decimal(data["markup_percentage"]),
      final_price: parse_decimal(data["final_price"]),
      valid_until: parse_date(data["valid_until"]),
      business_id: 1, # Asumiendo business_id = 1 para Gaepell
      user_id: user_id
    }

    case %Quotation{} |> Quotation.changeset(quotation_attrs) |> Repo.insert() do
      {:ok, quotation} ->
        # Procesar opciones de cotización si existen
        if data["quotation_options"] do
          process_quotation_options(quotation, data["quotation_options"])
        end
        
        {:ok, %{id: quotation.id, quotation_number: quotation.quotation_number}}
      
      {:error, changeset} ->
        {:error, "Error al crear cotización: #{inspect(changeset.errors)}"}
    end
  end

  defp process_sync_action("update", "quotation", data, _user_id) do
    case Repo.get(Quotation, data["id"]) do
      nil ->
        {:error, "Cotización no encontrada"}
      
      quotation ->
        update_attrs = %{
          client_name: data["client_name"],
          client_email: data["client_email"],
          client_phone: data["client_phone"],
          quantity: data["quantity"],
          special_requirements: data["special_requirements"],
          status: data["status"],
          total_cost: parse_decimal(data["total_cost"]),
          markup_percentage: parse_decimal(data["markup_percentage"]),
          final_price: parse_decimal(data["final_price"]),
          valid_until: parse_date(data["valid_until"])
        }

        case quotation |> Quotation.changeset(update_attrs) |> Repo.update() do
          {:ok, updated_quotation} ->
            {:ok, %{id: updated_quotation.id, quotation_number: updated_quotation.quotation_number}}
          
          {:error, changeset} ->
            {:error, "Error al actualizar cotización: #{inspect(changeset.errors)}"}
        end
    end
  end

  defp process_sync_action("create", "lead", data, user_id) do
    lead_attrs = %{
      name: data["name"],
      email: data["email"],
      phone: data["phone"],
      company: data["company"],
      source: data["source"] || "offline",
      status: data["status"] || "new",
      notes: data["notes"],
      business_id: 1,
      user_id: user_id
    }

    case %Lead{} |> Lead.changeset(lead_attrs) |> Repo.insert() do
      {:ok, lead} ->
        {:ok, %{id: lead.id, name: lead.name}}
      
      {:error, changeset} ->
        {:error, "Error al crear lead: #{inspect(changeset.errors)}"}
    end
  end

  defp process_sync_action("create", "activity", data, user_id) do
    activity_attrs = %{
      type: data["type"],
      title: data["title"],
      description: data["description"],
      due_date: parse_datetime(data["due_date"]),
      priority: data["priority"] || "medium",
      status: data["status"] || "pending",
      business_id: 1,
      user_id: user_id
    }

    case %Activity{} |> Activity.changeset(activity_attrs) |> Repo.insert() do
      {:ok, activity} ->
        {:ok, %{id: activity.id, title: activity.title}}
      
      {:error, changeset} ->
        {:error, "Error al crear actividad: #{inspect(changeset.errors)}"}
    end
  end

  defp process_sync_action("delete", type, data, _user_id) do
    case get_record_by_type(type, data["id"]) do
      nil ->
        {:error, "#{String.capitalize(type)} no encontrado"}
      
      record ->
        case Repo.delete(record) do
          {:ok, _} ->
            {:ok, %{id: data["id"], deleted: true}}
          
          {:error, _} ->
            {:error, "Error al eliminar #{type}"}
        end
    end
  end

  defp process_sync_action(action, type, _data, _user_id) do
    {:error, "Acción '#{action}' no soportada para tipo '#{type}'"}
  end

  # Procesar opciones de cotización
  defp process_quotation_options(quotation, options) do
    Enum.each(options, fn option_data ->
      option_attrs = %{
        option_name: option_data["option_name"],
        quality_level: option_data["quality_level"],
        production_cost: parse_decimal(option_data["production_cost"]),
        markup_percentage: parse_decimal(option_data["markup_percentage"]),
        final_price: parse_decimal(option_data["final_price"]),
        delivery_time_days: option_data["delivery_time_days"],
        is_recommended: option_data["is_recommended"] || false,
        quotation_id: quotation.id
      }

      %QuotationOption{} |> QuotationOption.changeset(option_attrs) |> Repo.insert()
    end)
  end

  # Obtener registro por tipo
  defp get_record_by_type("quotation", id), do: Repo.get(Quotation, id)
  defp get_record_by_type("lead", id), do: Repo.get(Lead, id)
  defp get_record_by_type("activity", id), do: Repo.get(Activity, id)
  defp get_record_by_type(_, _), do: nil

  # Generar número de cotización
  defp generate_quotation_number do
    today = Date.utc_today()
    month = today.month |> Integer.to_string() |> String.pad_leading(2, "0")
    year = today.year |> Integer.to_string()
    
    # Obtener el último número de cotización del mes
    last_quotation = Repo.one(
      from q in Quotation,
      where: fragment("EXTRACT(YEAR FROM ?)", q.inserted_at) == ^today.year and
             fragment("EXTRACT(MONTH FROM ?)", q.inserted_at) == ^today.month,
      order_by: [desc: q.inserted_at],
      limit: 1
    )

    case last_quotation do
      nil ->
        "COT-#{year}#{month}-001"
      
      _ ->
        # Extraer el número y incrementarlo
        case Regex.run(~r/COT-\d{6}-(\d{3})/, last_quotation.quotation_number) do
          [_, number_str] ->
            next_number = String.to_integer(number_str) + 1
            "COT-#{year}#{month}-#{next_number |> Integer.to_string() |> String.pad_leading(3, "0")}"
          
          _ ->
            "COT-#{year}#{month}-001"
        end
    end
  end

  # Parsear decimal
  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {:ok, decimal} -> decimal
      :error -> Decimal.new(0)
    end
  end
  defp parse_decimal(value) when is_number(value), do: Decimal.new(value)
  defp parse_decimal(_), do: Decimal.new(0)

  # Parsear fecha
  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      :error -> Date.utc_today()
    end
  end
  defp parse_date(_), do: Date.utc_today()

  # Parsear datetime
  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} -> datetime
      :error -> DateTime.utc_now()
    end
  end
  defp parse_datetime(_), do: DateTime.utc_now()
end 