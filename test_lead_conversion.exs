#!/usr/bin/env elixir

# Script para probar la conversión de leads a contactos y órdenes de producción
# Ejecutar con: mix run test_lead_conversion.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead, Contact, ProductionOrder, Workflow, WorkflowState}

IO.puts("=== PRUEBA DE CONVERSIÓN DE LEADS ===")
IO.puts("")

# Función de conversión (copiada del LiveView)
convert_lead_to_contact_and_production_order = fn lead ->
  # Log para depuración
  IO.puts("=== INICIANDO CONVERSIÓN DE LEAD ===")
  IO.puts("Lead ID: #{lead.id}")
  IO.puts("Lead Name: #{lead.name}")
  IO.puts("Lead Status: #{lead.status}")
  
  # Obtener el workflow de producción para Furcar (business_id: 1)
  workflow = Repo.get_by(EvaaCrmGaepell.Workflow, workflow_type: "production", business_id: 1)
  
  case workflow do
    nil ->
      IO.puts("❌ No se encontró workflow de producción")
      {:error, "Workflow no encontrado"}
    
    workflow ->
      IO.puts("✅ Workflow encontrado: #{workflow.id}")
      
      # Obtener el estado inicial "new_order"
      initial_state = Repo.get_by(EvaaCrmGaepell.WorkflowState, name: "new_order", workflow_id: workflow.id)
      
      case initial_state do
        nil ->
          IO.puts("❌ No se encontró estado inicial")
          {:error, "Estado inicial no encontrado"}
        
        initial_state ->
          IO.puts("✅ Estado inicial encontrado: #{initial_state.id}")
          
          # Crear el contacto desde el lead
          contact_attrs = %{
            "first_name" => lead.name,
            "last_name" => "Cliente",
            "email" => lead.email,
            "phone" => lead.phone,
            "job_title" => "Cliente",
            "department" => "",
            "address" => "",
            "city" => "",
            "state" => "",
            "country" => "",
            "status" => "active",
            "source" => "other",
            "notes" => "Cliente convertido desde lead: #{lead.name}",
            "business_id" => lead.business_id,
            "company_id" => lead.company_id
          }
          
          IO.puts("Creando contacto con: #{inspect(contact_attrs)}")
          
          case %EvaaCrmGaepell.Contact{}
               |> EvaaCrmGaepell.Contact.changeset(contact_attrs)
               |> Repo.insert() do
            {:ok, contact} ->
              IO.puts("✅ Contacto creado exitosamente: #{contact.id}")
              
              # Crear la orden de producción
              production_order_attrs = %{
                "client_name" => lead.name,
                "truck_brand" => "Por definir",
                "truck_model" => "Por definir", 
                "license_plate" => "Por definir",
                "box_type" => "dry_box",
                "specifications" => "Orden creada automáticamente desde lead convertido: #{lead.name}",
                "estimated_delivery" => Date.add(Date.utc_today(), 30),
                "status" => "new_order",
                "notes" => "Orden creada automáticamente desde lead convertido",
                "business_id" => lead.business_id,
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
                  IO.puts("=== CONVERSIÓN COMPLETADA ===")
                  {:ok, contact}
                {:error, changeset} ->
                  IO.puts("❌ Error al crear orden de producción: #{inspect(changeset.errors)}")
                  # Si falla la creación de la orden, eliminar el contacto creado
                  Repo.delete(contact)
                  {:error, changeset}
              end
            
            {:error, changeset} ->
              IO.puts("❌ Error al crear contacto: #{inspect(changeset.errors)}")
              {:error, changeset}
          end
      end
  end
end

# Obtener un lead para probar
leads = Repo.all(Lead) |> Repo.preload(:company)
if length(leads) > 0 do
  lead = List.first(leads)
  IO.puts("Lead seleccionado para prueba:")
  IO.puts("  ID: #{lead.id}")
  IO.puts("  Nombre: #{lead.name}")
  IO.puts("  Estado actual: #{lead.status}")
  IO.puts("  Empresa: #{lead.business_id}")
  IO.puts("")

  # Verificar que el lead no esté ya convertido
  if lead.status != "converted" do
    IO.puts("--- PROBANDO CONVERSIÓN DE LEAD ---")
    
    # Simular la conversión
    case convert_lead_to_contact_and_production_order.(lead) do
      {:ok, contact} ->
        IO.puts("✅ CONVERSIÓN EXITOSA")
        IO.puts("Contacto creado: #{contact.id}")
        
        # Verificar que se creó la orden de producción
        production_order = Repo.get_by(ProductionOrder, contact_id: contact.id)
        if production_order do
          IO.puts("Orden de producción creada: #{production_order.id}")
          IO.puts("Cliente: #{production_order.client_name}")
          IO.puts("Estado: #{production_order.status}")
        else
          IO.puts("❌ No se encontró la orden de producción")
        end
        
      {:error, error} ->
        IO.puts("❌ ERROR EN CONVERSIÓN: #{error}")
    end
  else
    IO.puts("El lead ya está convertido, no se puede probar la conversión")
  end
else
  IO.puts("No hay leads disponibles para probar")
end

IO.puts("\nPrueba completada.") 