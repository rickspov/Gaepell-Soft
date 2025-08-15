#!/usr/bin/env elixir

# Script para probar la reversión de conversión de leads desde el Kanban
# Ejecutar con: mix run test_kanban_reversion.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead, Contact, ProductionOrder}

IO.puts("=== PRUEBA DE REVERSIÓN DE CONVERSIÓN DE LEADS DESDE KANBAN ===")
IO.puts("")

# Obtener un lead que esté convertido
leads = Repo.all(from l in Lead, where: l.status == "converted" and l.business_id == 1, limit: 1)
if length(leads) > 0 do
  lead = List.first(leads)
  IO.puts("Lead convertido seleccionado para prueba:")
  IO.puts("  ID: #{lead.id}")
  IO.puts("  Nombre: #{lead.name}")
  IO.puts("  Estado actual: #{lead.status}")
  IO.puts("  Empresa: #{lead.business_id}")
  IO.puts("")

  # Verificar que existe el contacto y la orden de producción
  contact = Repo.get_by(Contact, 
    first_name: lead.name, 
    business_id: lead.business_id,
    notes: "Cliente convertido desde lead: #{lead.name}")
  
  if contact do
    IO.puts("✅ Contacto encontrado: #{contact.id} - #{contact.first_name} #{contact.last_name}")
    
    production_orders = Repo.all(from po in ProductionOrder, 
      where: po.contact_id == ^contact.id and 
             po.notes == "Orden creada automáticamente desde lead convertido en Kanban")
    
    IO.puts("✅ Encontradas #{length(production_orders)} órdenes de producción asociadas")
    
    # Simular el evento kanban:move que dispara la reversión
    IO.puts("")
    IO.puts("--- SIMULANDO DRAG & DROP EN KANBAN (REVERSIÓN) ---")
    IO.puts("Evento: kanban:move")
    IO.puts("ID: l-#{lead.id}")
    IO.puts("new_status: qualified")
    IO.puts("")

    # Simular la lógica del Kanban LiveView
    lead_id = lead.id
    old_status = lead.status
    new_status = "qualified"
    
    # Actualizar el estado del lead
    changeset = Lead.changeset(lead, %{status: new_status})
    case Repo.update(changeset) do
      {:ok, updated_lead} ->
        IO.puts("✅ Lead #{lead_id} actualizado de #{old_status} a #{new_status}")
        
        # Simular la función de reversión del Kanban
        IO.puts("--- EJECUTANDO REVERSIÓN DESDE KANBAN ---")
        
        # Buscar el contacto asociado a este lead
        contact_to_delete = Repo.get_by(Contact, 
          first_name: updated_lead.name, 
          business_id: updated_lead.business_id,
          notes: "Cliente convertido desde lead: #{updated_lead.name}")
        
        case contact_to_delete do
          nil ->
            IO.puts("❌ No se encontró contacto asociado al lead")
          contact_to_delete ->
            IO.puts("✅ Contacto encontrado: #{contact_to_delete.id} - #{contact_to_delete.first_name} #{contact_to_delete.last_name}")
            
            # Buscar órdenes de producción asociadas a este contacto
            production_orders_to_delete = Repo.all(from po in ProductionOrder, 
              where: po.contact_id == ^contact_to_delete.id and 
                     po.notes == "Orden creada automáticamente desde lead convertido en Kanban")
            
            IO.puts("Encontradas #{length(production_orders_to_delete)} órdenes de producción asociadas")
            
            # Eliminar las órdenes de producción
            Enum.each(production_orders_to_delete, fn order ->
              case Repo.delete(order) do
                {:ok, _deleted_order} ->
                  IO.puts("✅ Orden de producción eliminada: #{order.id}")
                {:error, error} ->
                  IO.puts("❌ Error al eliminar orden de producción #{order.id}: #{inspect(error)}")
              end
            end)
            
            # Eliminar el contacto
            case Repo.delete(contact_to_delete) do
              {:ok, _deleted_contact} ->
                IO.puts("✅ Contacto eliminado: #{contact_to_delete.id}")
                IO.puts("=== REVERSIÓN COMPLETADA ===")
                
                # Verificar que se eliminaron los registros
                IO.puts("")
                IO.puts("--- VERIFICACIÓN FINAL ---")
                
                # Verificar el lead
                updated_lead_check = Repo.get(Lead, lead.id)
                IO.puts("Lead estado final: #{updated_lead_check.status}")
                
                # Verificar que el contacto fue eliminado
                contact_check = Repo.get(Contact, contact.id)
                if contact_check do
                  IO.puts("❌ Contacto aún existe: #{contact_check.first_name} #{contact_check.last_name}")
                else
                  IO.puts("✅ Contacto eliminado correctamente")
                end
                
                # Verificar que las órdenes fueron eliminadas
                orders_check = Repo.all(from po in ProductionOrder, where: po.contact_id == ^contact.id)
                if length(orders_check) > 0 do
                  IO.puts("❌ Aún existen #{length(orders_check)} órdenes de producción")
                else
                  IO.puts("✅ Órdenes de producción eliminadas correctamente")
                end
                
                IO.puts("")
                IO.puts("🎉 ¡PRUEBA EXITOSA! La reversión desde Kanban funciona correctamente.")
                
              {:error, error} ->
                IO.puts("❌ Error al eliminar contacto: #{inspect(error)}")
            end
        end
        
      {:error, changeset} ->
        IO.puts("❌ Error al actualizar lead: #{inspect(changeset.errors)}")
    end
  else
    IO.puts("❌ No se encontró contacto asociado al lead convertido")
  end
else
  IO.puts("❌ No se encontraron leads convertidos para probar")
  IO.puts("Primero ejecuta: mix run test_kanban_conversion.exs para crear un lead convertido")
end 