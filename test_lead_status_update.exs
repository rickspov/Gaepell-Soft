#!/usr/bin/env elixir

# Script para probar la actualización de estado de leads
# Ejecutar con: mix run test_lead_status_update.exs

import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead}

IO.puts("=== PRUEBA DE ACTUALIZACIÓN DE ESTADO DE LEADS ===")
IO.puts("")

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

  # Probar cambio de estado
  new_status = case lead.status do
    "new" -> "contacted"
    "contacted" -> "qualified"
    "qualified" -> "converted"
    "converted" -> "lost"
    "lost" -> "new"
    _ -> "contacted"
  end

  IO.puts("--- PROBANDO CAMBIO DE ESTADO ---")
  IO.puts("Estado actual: #{lead.status}")
  IO.puts("Nuevo estado: #{new_status}")
  IO.puts("")

  # Crear changeset y actualizar
  changeset = Lead.changeset(lead, %{status: new_status})
  IO.puts("Changeset válido: #{changeset.valid?}")
  
  if changeset.valid? do
    case Repo.update(changeset) do
      {:ok, updated_lead} ->
        IO.puts("✅ Lead actualizado exitosamente")
        IO.puts("  Nuevo estado: #{updated_lead.status}")
        IO.puts("  Actualizado en: #{updated_lead.updated_at}")
        
        # Verificar que se guardó en la base de datos
        reloaded_lead = Repo.get(Lead, lead.id)
        IO.puts("  Estado en BD: #{reloaded_lead.status}")
        
        if reloaded_lead.status == new_status do
          IO.puts("✅ Estado persistido correctamente en la base de datos")
        else
          IO.puts("❌ ERROR: Estado no se persistió correctamente")
        end
        
      {:error, changeset} ->
        IO.puts("❌ Error al actualizar lead:")
        IO.puts("  Errores: #{inspect(changeset.errors)}")
    end
  else
    IO.puts("❌ Changeset inválido:")
    IO.puts("  Errores: #{inspect(changeset.errors)}")
  end
else
  IO.puts("❌ No hay leads en la base de datos para probar")
end

IO.puts("")
IO.puts("=== VERIFICACIÓN DE TODOS LOS LEADS ===")
all_leads = Repo.all(Lead) |> Repo.preload(:company)
Enum.each(all_leads, fn lead ->
  company_name = case lead.business_id do
    1 -> "Furcar"
    2 -> "Blidomca"
    3 -> "Polimat"
    _ -> "Empresa #{lead.business_id}"
  end
  
  IO.puts("  Lead #{lead.id}: #{lead.name} | Estado: #{lead.status} | Empresa: #{company_name}")
end)

IO.puts("")
IO.puts("=== PRUEBA COMPLETADA ===") 