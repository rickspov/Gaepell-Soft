#!/usr/bin/env elixir

# Script para probar el nuevo filtro de fecha con rangos
# Ejecutar con: mix run test_date_filter.exs

alias EvaaCrmGaepell.{Repo, Activity, MaintenanceTicket, ProductionOrder, Lead}
import Ecto.Query

IO.puts("=== PROBANDO NUEVO FILTRO DE FECHA CON RANGOS ===")

# Función para simular el filtro de fecha
defmodule DateFilterTest do
  def apply_date_filter(query, fecha) when is_binary(fecha) and fecha != "" and fecha != "todos" do
    today = Date.utc_today()
    
    case fecha do
      "semana" ->
        from(a in query, where: fragment("DATE(?)", a.due_date) >= ^Date.add(today, -7))
      "15_dias" ->
        from(a in query, where: fragment("DATE(?)", a.due_date) >= ^Date.add(today, -15))
      "30_dias" ->
        from(a in query, where: fragment("DATE(?)", a.due_date) >= ^Date.add(today, -30))
      "60_dias" ->
        from(a in query, where: fragment("DATE(?)", a.due_date) >= ^Date.add(today, -60))
      "120_dias" ->
        from(a in query, where: fragment("DATE(?)", a.due_date) >= ^Date.add(today, -120))
      _ -> query
    end
  end
  def apply_date_filter(query, _), do: query
end

# Probar con diferentes rangos
filters = ["todos", "semana", "15_dias", "30_dias", "60_dias", "120_dias"]

Enum.each(filters, fn filter ->
  IO.puts("\n--- Probando filtro: #{filter} ---")
  
  # Probar con actividades
  activities_query = from(a in Activity, order_by: a.due_date)
  filtered_activities = DateFilterTest.apply_date_filter(activities_query, filter)
  activities_count = Repo.aggregate(filtered_activities, :count, :id)
  IO.puts("Actividades: #{activities_count}")
  
  # Probar con tickets
  tickets_query = from(m in MaintenanceTicket, order_by: m.entry_date)
  filtered_tickets = DateFilterTest.apply_date_filter(tickets_query, filter)
  tickets_count = Repo.aggregate(filtered_tickets, :count, :id)
  IO.puts("Tickets: #{tickets_count}")
  
  # Probar con órdenes de producción
  orders_query = from(po in ProductionOrder, order_by: po.estimated_delivery)
  filtered_orders = DateFilterTest.apply_date_filter(orders_query, filter)
  orders_count = Repo.aggregate(filtered_orders, :count, :id)
  IO.puts("Órdenes: #{orders_count}")
  
  # Probar con leads
  leads_query = from(l in Lead, order_by: l.next_follow_up)
  filtered_leads = DateFilterTest.apply_date_filter(leads_query, filter)
  leads_count = Repo.aggregate(filtered_leads, :count, :id)
  IO.puts("Leads: #{leads_count}")
end)

IO.puts("\n=== PRUEBA COMPLETADA ===")
IO.puts("El nuevo filtro de fecha debería funcionar correctamente.")
IO.puts("Accede a: http://localhost:4000 para probar los nuevos filtros de período.") 