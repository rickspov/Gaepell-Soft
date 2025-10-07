defmodule EvaaCrmGaepell.TicketCodeGenerator do
  @moduledoc """
  Módulo para generar códigos de tickets con formato YYMMNNN
  donde YY es el año, MM es el mes y NNN es el número secuencial del mes
  """

  import Ecto.Query

  @doc """
  Genera un código de ticket para el tipo especificado.
  
  ## Ejemplos
  
      iex> generate_ticket_code(:maintenance)
      "250901"
      
      iex> generate_ticket_code(:evaluation) 
      "250902"
      
      iex> generate_ticket_code(:production)
      "250903"
  """
  def generate_ticket_code(ticket_type) do
    now = DateTime.utc_now()
    year = rem(now.year, 100)  # Obtener los últimos 2 dígitos del año
    month = now.month
    
    # Obtener el siguiente número secuencial para este mes y tipo
    next_number = get_next_sequence_number(ticket_type, year, month)
    
    # Formatear como YYMMNNN
    String.pad_leading("#{year}#{String.pad_leading("#{month}", 2, "0")}#{next_number}", 6, "0")
  end

  @doc """
  Obtiene el siguiente número secuencial para un tipo de ticket en un mes específico.
  """
  def get_next_sequence_number(ticket_type, year, month) do
    # Buscar el último ticket del mismo tipo en el mismo mes
    last_ticket = get_last_ticket_of_month(ticket_type, year, month)
    
    case last_ticket do
      nil -> 1  # Primer ticket del mes
      ticket -> extract_sequence_number(ticket.ticket_code) + 1
    end
  end

  @doc """
  Extrae el número secuencial de un código de ticket existente.
  """
  def extract_sequence_number(ticket_code) when is_binary(ticket_code) do
    case String.length(ticket_code) do
      6 -> 
        # Formato YYMMNNN
        String.slice(ticket_code, 4, 2) |> String.to_integer()
      _ -> 
        0
    end
  end

  def extract_sequence_number(_), do: 0

  defp get_last_ticket_of_month(ticket_type, year, month) do
    case ticket_type do
      :maintenance ->
        EvaaCrmGaepell.Repo.one(
          from t in EvaaCrmGaepell.MaintenanceTicket,
          where: fragment("EXTRACT(YEAR FROM inserted_at) = ?", ^year),
          where: fragment("EXTRACT(MONTH FROM inserted_at) = ?", ^month),
          where: not is_nil(t.ticket_code),
          order_by: [desc: t.inserted_at],
          limit: 1
        )
      
      :evaluation ->
        EvaaCrmGaepell.Repo.one(
          from e in EvaaCrmGaepell.Evaluation,
          where: fragment("EXTRACT(YEAR FROM inserted_at) = ?", ^year),
          where: fragment("EXTRACT(MONTH FROM inserted_at) = ?", ^month),
          where: not is_nil(e.ticket_code),
          order_by: [desc: e.inserted_at],
          limit: 1
        )
      
      :production ->
        EvaaCrmGaepell.Repo.one(
          from p in EvaaCrmGaepell.ProductionOrder,
          where: fragment("EXTRACT(YEAR FROM inserted_at) = ?", ^year),
          where: fragment("EXTRACT(MONTH FROM inserted_at) = ?", ^month),
          where: not is_nil(p.ticket_code),
          order_by: [desc: p.inserted_at],
          limit: 1
        )
    end
  end

  @doc """
  Genera códigos para tickets existentes que no tienen código.
  """
  def generate_codes_for_existing_tickets do
    # Generar códigos para maintenance tickets
    generate_codes_for_table(:maintenance, EvaaCrmGaepell.MaintenanceTicket)
    
    # Generar códigos para evaluations
    generate_codes_for_table(:evaluation, EvaaCrmGaepell.Evaluation)
    
    # Generar códigos para production orders
    generate_codes_for_table(:production, EvaaCrmGaepell.ProductionOrder)
  end

  defp generate_codes_for_table(_ticket_type, schema) do
    # Obtener todos los tickets sin código, ordenados por fecha de creación
    tickets = EvaaCrmGaepell.Repo.all(
      from t in schema,
      where: is_nil(t.ticket_code),
      order_by: [asc: t.inserted_at]
    )
    
    # Agrupar por mes y año
    tickets_by_month = Enum.group_by(tickets, fn ticket ->
      {ticket.inserted_at.year, ticket.inserted_at.month}
    end)
    
    # Generar códigos para cada grupo
    Enum.each(tickets_by_month, fn {{year, month}, month_tickets} ->
      Enum.with_index(month_tickets, 1)
      |> Enum.each(fn {ticket, index} ->
        year_short = rem(year, 100)
        month_padded = String.pad_leading("#{month}", 2, "0")
        sequence_padded = String.pad_leading("#{index}", 2, "0")
        ticket_code = "#{year_short}#{month_padded}#{sequence_padded}"
        
        # Actualizar el ticket con el código
        ticket
        |> Ecto.Changeset.change(ticket_code: ticket_code)
        |> EvaaCrmGaepell.Repo.update!()
      end)
    end)
  end
end