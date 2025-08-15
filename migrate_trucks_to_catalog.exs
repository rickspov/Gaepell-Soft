#!/usr/bin/env elixir

# Script para migrar camiones existentes al catálogo de modelos
# Ejecutar con: mix run migrate_trucks_to_catalog.exs

IO.puts("🚛 Iniciando migración de camiones al catálogo...")

# Inicializar la aplicación
Application.ensure_all_started(:evaa_crm_gaepell)

alias EvaaCrmGaepell.{Repo, Truck, TruckModel}
import Ecto.Query

# Obtener todos los camiones existentes
trucks = Repo.all(from t in Truck, order_by: t.inserted_at)

IO.puts("📊 Total de camiones encontrados: #{length(trucks)}")

# Contadores para el reporte
created_count = 0
updated_count = 0
skipped_count = 0

Enum.each(trucks, fn truck ->
  # Verificar si ya existe un modelo con la misma marca, modelo y año
  existing_model = TruckModel.get_model(truck.brand, truck.model, truck.year, truck.business_id)
  
  case existing_model do
    nil ->
      # Crear nuevo modelo
      truck_model_attrs = %{
        brand: truck.brand,
        model: truck.model,
        year: truck.year,
        capacity: truck.capacity,
        fuel_type: truck.fuel_type,
        business_id: truck.business_id,
        usage_count: 1,
        last_used_at: truck.inserted_at || DateTime.utc_now()
      }
      
      case %TruckModel{}
           |> TruckModel.changeset(truck_model_attrs)
           |> Repo.insert() do
        {:ok, _model} ->
          created_count = created_count + 1
          IO.puts("✅ Creado: #{truck.brand} #{truck.model} (#{truck.year})")
        
        {:error, changeset} ->
          IO.puts("❌ Error creando modelo #{truck.brand} #{truck.model}: #{inspect(changeset.errors)}")
      end
    
    existing_model ->
      # Incrementar el contador de uso
      case existing_model
           |> TruckModel.changeset(%{
             usage_count: existing_model.usage_count + 1,
             last_used_at: DateTime.utc_now()
           })
           |> Repo.update() do
        {:ok, _model} ->
          updated_count = updated_count + 1
          IO.puts("🔄 Actualizado: #{truck.brand} #{truck.model} (#{truck.year}) - Usos: #{existing_model.usage_count + 1}")
        
        {:error, changeset} ->
          IO.puts("❌ Error actualizando modelo #{truck.brand} #{truck.model}: #{inspect(changeset.errors)}")
      end
  end
end)

# Reporte final
IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("📋 REPORTE DE MIGRACIÓN")
IO.puts(String.duplicate("=", 50))
IO.puts("✅ Modelos creados: #{created_count}")
IO.puts("🔄 Modelos actualizados: #{updated_count}")
IO.puts("📊 Total procesados: #{created_count + updated_count}")
IO.puts("🎯 Camiones en catálogo: #{Repo.aggregate(TruckModel, :count)}")

# Mostrar algunos ejemplos del catálogo
IO.puts("\n📚 Ejemplos del catálogo:")
catalog_examples = Repo.all(
  from tm in TruckModel,
  order_by: [desc: tm.usage_count, desc: tm.last_used_at],
  limit: 10
)

Enum.each(catalog_examples, fn model ->
  IO.puts("  • #{model.brand} #{model.model} (#{model.year}) - #{model.usage_count} usos")
end)

IO.puts("\n🎉 ¡Migración completada exitosamente!") 