#!/usr/bin/env elixir

# Script para probar la conversión de leads desde el Kanban
# Ejecutar con: mix run test_kanban_conversion.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead, Contact, ProductionOrder}

IO.puts("=== PRUEBA DE CONVERSIÓN DE LEADS DESDE KANBAN ===")
IO.puts("")

# Obtener un lead que no esté convertido
leads = Repo.all(from l in Lead, where: l.status != "converted" and l.business_id == 1, limit: 1)
if length(leads) > 0 do
  lead = List.first(leads)
  IO.puts("Lead seleccionado para prueba:")
  IO.puts("  ID: #{lead.id}")
  IO.puts("  Nombre: #{lead.name}")
  IO.puts("  Estado actual: #{lead.status}")
  IO.puts("  Empresa: #{lead.business_id}")
  IO.puts("")

  # Simular el evento kanban:move que dispara la conversión
  IO.puts("--- SIMULANDO DRAG & DROP EN KANBAN ---")
  IO.puts("Evento: kanban:move")
  IO.puts("ID: l-#{lead.id}")
  IO.puts("new_status: converted")
  IO.puts("")

  # Simular la lógica del Kanban LiveView
  lead_id = lead.id
  new_status = "converted"
  
  # Actualizar el estado del lead
  changeset = Lead.changeset(lead, %{status: new_status})
  case Repo.update(changeset) do
    {:ok, updated_lead} ->
      IO.puts("✅ Lead #{lead_id} actualizado a estado: #{new_status}")
      
      # Simular la función de conversión del Kanban
      IO.puts("--- EJECUTANDO CONVERSIÓN DESDE KANBAN ---")
      
      # Obtener el workflow de producción para la empresa del lead
      workflow = Repo.get_by(EvaaCrmGaepell.Workflow, workflow_type: "production", business_id: updated_lead.business_id)
      
      case workflow do
        nil ->
          IO.puts("❌ No se encontró workflow de producción para business_id: #{updated_lead.business_id}")
        workflow ->
          IO.puts("✅ Workflow encontrado: #{workflow.id}")
          
          # Obtener el estado inicial "new_order"
          initial_state = Repo.get_by(EvaaCrmGaepell.WorkflowState, name: "new_order", workflow_id: workflow.id)
          
          case initial_state do
            nil ->
              IO.puts("❌ No se encontró estado inicial")
            initial_state ->
              IO.puts("✅ Estado inicial encontrado: #{initial_state.id}")
              
              # Crear el contacto desde el lead
              contact_attrs = %{
                "first_name" => updated_lead.name,
                "last_name" => "Cliente",
                "email" => updated_lead.email,
                "phone" => updated_lead.phone,
                "job_title" => "Cliente",
                "department" => "",
                "address" => "",
                "city" => "",
                "state" => "",
                "country" => "",
                "status" => "active",
                "source" => "other",
                "notes" => "Cliente convertido desde lead en Kanban: #{updated_lead.name}",
                "business_id" => updated_lead.business_id,
                "company_id" => updated_lead.company_id
              }
              
              IO.puts("Creando contacto con: #{inspect(contact_attrs)}")
              
              case %EvaaCrmGaepell.Contact{}
                   |> EvaaCrmGaepell.Contact.changeset(contact_attrs)
                   |> Repo.insert() do
                {:ok, contact} ->
                  IO.puts("✅ Contacto creado exitosamente: #{contact.id}")
                  
                  # Crear la orden de producción
                  production_order_attrs = %{
                    "client_name" => updated_lead.name,
                    "truck_brand" => "Por definir",
                    "truck_model" => "Por definir", 
                    "license_plate" => "Por definir",
                    "box_type" => "dry_box",
                    "specifications" => "Orden creada automáticamente desde lead convertido en Kanban: #{updated_lead.name}",
                    "estimated_delivery" => Date.add(Date.utc_today(), 30),
                    "status" => "new_order",
                    "notes" => "Orden creada automáticamente desde lead convertido en Kanban",
                    "business_id" => updated_lead.business_id,
                    "workflow_id" => workflow.id,
                    "workflow_state_id" => initial_state.id,
                    "contact_id" => contact.id
                  }
                  
                  IO.puts("Creando orden de producción con: #{inspect(production_order_attrs)}")
                  
                  case %EvaaCrmGaepell.ProductionOrder{}
                       |> EvaaCrmGaepell.ProductionOrder.changeset(production_order_attrs)
                       |> Repo.insert() do
                    {:ok, production_order} ->
                      IO.puts("✅ Orden de producción creada exitosamente: #{production_order.id}")
                      IO.puts("=== CONVERSIÓN COMPLETADA DESDE KANBAN ===")
                      
                      # Verificar que se crearon los registros
                      IO.puts("")
                      IO.puts("--- VERIFICACIÓN FINAL ---")
                      
                      # Verificar el lead
                      updated_lead_check = Repo.get(Lead, lead.id)
                      IO.puts("Lead estado final: #{updated_lead_check.status}")
                      
                      # Verificar el contacto
                      contact_check = Repo.get(Contact, contact.id)
                      IO.puts("Contacto creado: #{contact_check.first_name} #{contact_check.last_name}")
                      
                      # Verificar la orden de producción
                      order_check = Repo.get(ProductionOrder, production_order.id)
                      IO.puts("Orden de producción creada: #{order_check.client_name}")
                      
                      IO.puts("")
                      IO.puts("🎉 ¡PRUEBA EXITOSA! La conversión desde Kanban funciona correctamente.")
                      
                    {:error, changeset} ->
                      IO.puts("❌ Error al crear orden de producción: #{inspect(changeset.errors)}")
                      # Si falla la creación de la orden, eliminar el contacto creado
                      Repo.delete(contact)
                  end
                
                {:error, changeset} ->
                  IO.puts("❌ Error al crear contacto: #{inspect(changeset.errors)}")
              end
          end
      end
      
    {:error, changeset} ->
      IO.puts("❌ Error al actualizar lead: #{inspect(changeset.errors)}")
  end
else
  IO.puts("❌ No se encontraron leads para probar")
end 