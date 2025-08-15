#!/usr/bin/env elixir

# Script para probar el sistema de cotizaciones - Versión Gaepell
# Ejecutar con: mix run test_quotations_system.exs

alias EvaaCrmGaepell.{Repo, MaterialCategory, Material, Quotation, QuotationOption, Business, User}
import Ecto.Query

IO.puts("📦 Probando Sistema de Cotizaciones e Inventario Inteligente - Gaepell")
IO.puts("=" <> String.duplicate("=", 70))

# Obtener el business (asumiendo que es el primero)
business = Repo.one(from b in Business, limit: 1)

if is_nil(business) do
  IO.puts("❌ No se encontró ningún business. Creando uno...")
  
  business = %Business{}
  |> Business.changeset(%{name: "Gaepell - Empresa de Cajas"})
  |> Repo.insert!()
  
  IO.puts("✅ Business creado: #{business.name}")
else
  IO.puts("✅ Business encontrado: #{business.name}")
end

# Obtener o crear usuario
user = Repo.one(from u in User, where: u.business_id == ^business.id, limit: 1)

if is_nil(user) do
  IO.puts("❌ No se encontró ningún usuario. Creando uno...")
  
  user = %User{}
  |> User.changeset(%{
    email: "admin@gaepell.com",
    password: "password",
    role: "admin",
    business_id: business.id
  })
  |> Repo.insert!()
  
  IO.puts("✅ Usuario creado: #{user.email}")
else
  IO.puts("✅ Usuario encontrado: #{user.email}")
end

# Crear categorías de materiales
IO.puts("\n📋 Creando categorías de materiales...")

categories = [
  %{name: "Cartón", description: "Diferentes tipos de cartón", color: "#8B4513"},
  %{name: "Papel", description: "Papeles especializados", color: "#F5F5DC"},
  %{name: "Adhesivos", description: "Pegamentos y adhesivos", color: "#FFD700"},
  %{name: "Acabados", description: "Materiales de acabado", color: "#C0C0C0"}
]

created_categories = Enum.map(categories, fn cat_attrs ->
  case Repo.get_by(MaterialCategory, name: cat_attrs.name, business_id: business.id) do
    nil ->
      category = %MaterialCategory{}
      |> MaterialCategory.changeset(Map.put(cat_attrs, :business_id, business.id))
      |> Repo.insert!()
      IO.puts("✅ Categoría creada: #{category.name}")
      category
    existing ->
      IO.puts("✅ Categoría existente: #{existing.name}")
      existing
  end
end)

# Crear materiales
IO.puts("\n📦 Creando materiales...")

materials_data = [
  # Cartón
  %{name: "Cartón Corrugado 3mm", description: "Cartón corrugado de 3mm de grosor", unit: "m2", cost_per_unit: "15.50", category_name: "Cartón"},
  %{name: "Cartón Corrugado 5mm", description: "Cartón corrugado de 5mm de grosor", unit: "m2", cost_per_unit: "22.00", category_name: "Cartón"},
  %{name: "Cartón Microcorrugado", description: "Cartón microcorrugado fino", unit: "m2", cost_per_unit: "12.00", category_name: "Cartón"},
  
  # Papel
  %{name: "Papel Kraft 80g", description: "Papel kraft de 80 gramos", unit: "m2", cost_per_unit: "8.50", category_name: "Papel"},
  %{name: "Papel Couché 150g", description: "Papel couché de 150 gramos", unit: "m2", cost_per_unit: "18.00", category_name: "Papel"},
  %{name: "Papel Metalizado", description: "Papel metalizado premium", unit: "m2", cost_per_unit: "35.00", category_name: "Papel"},
  
  # Adhesivos
  %{name: "Pegamento PVA", description: "Pegamento PVA para cartón", unit: "litros", cost_per_unit: "45.00", category_name: "Adhesivos"},
  %{name: "Cinta Doble Cara", description: "Cinta adhesiva doble cara", unit: "metros", cost_per_unit: "2.50", category_name: "Adhesivos"},
  
  # Acabados
  %{name: "Barniz UV", description: "Barniz UV para acabado", unit: "litros", cost_per_unit: "120.00", category_name: "Acabados"},
  %{name: "Foil Dorado", description: "Foil dorado para estampado", unit: "m2", cost_per_unit: "85.00", category_name: "Acabados"}
]

created_materials = Enum.map(materials_data, fn mat_attrs ->
  category = Enum.find(created_categories, fn cat -> cat.name == mat_attrs.category_name end)
  
  case Repo.get_by(Material, name: mat_attrs.name, business_id: business.id) do
    nil ->
      material = %Material{}
      |> Material.changeset(%{
        name: mat_attrs.name,
        description: mat_attrs.description,
        unit: mat_attrs.unit,
        cost_per_unit: Decimal.new(mat_attrs.cost_per_unit),
        current_stock: Decimal.new("100.0"),
        min_stock: Decimal.new("10.0"),
        supplier: "Proveedor Principal",
        business_id: business.id,
        category_id: category.id
      })
      |> Repo.insert!()
      IO.puts("✅ Material creado: #{material.name} - $#{Decimal.to_string(material.cost_per_unit)}/#{material.unit}")
      material
    existing ->
      IO.puts("✅ Material existente: #{existing.name}")
      existing
  end
end)

# Crear cotización de ejemplo
IO.puts("\n📋 Creando cotización de ejemplo...")

quotation_number = Quotation.generate_quotation_number(business.id)

quotation = %Quotation{}
|> Quotation.changeset(%{
  quotation_number: quotation_number,
  client_name: "Empresa ABC",
  client_email: "compras@empresaabc.com",
  client_phone: "+1 (555) 123-4567",
  quantity: 100,
  special_requirements: "Cajas para productos electrónicos con protección antiestática",
  status: "draft",
  total_cost: Decimal.new("2500.00"),
  markup_percentage: Decimal.new("30.0"),
  final_price: Decimal.new("3250.00"),
  valid_until: Date.add(Date.utc_today(), 30),
  business_id: business.id,
  user_id: user.id
})
|> Repo.insert!()

IO.puts("✅ Cotización creada: #{quotation.quotation_number}")

# Crear opciones de cotización
IO.puts("\n💰 Creando opciones de cotización...")

options_data = [
  %{
    option_name: "Opción Premium",
    quality_level: "premium",
    production_cost: Decimal.new("2800.00"),
    markup_percentage: Decimal.new("40.0"),
    final_price: Decimal.new("3920.00"),
    delivery_time_days: 5,
    is_recommended: false
  },
  %{
    option_name: "Opción Estándar",
    quality_level: "standard",
    production_cost: Decimal.new("2500.00"),
    markup_percentage: Decimal.new("30.0"),
    final_price: Decimal.new("3250.00"),
    delivery_time_days: 7,
    is_recommended: true
  },
  %{
    option_name: "Opción Económica",
    quality_level: "economy",
    production_cost: Decimal.new("2000.00"),
    markup_percentage: Decimal.new("20.0"),
    final_price: Decimal.new("2400.00"),
    delivery_time_days: 10,
    is_recommended: false
  }
]

Enum.each(options_data, fn option_attrs ->
  option = %QuotationOption{}
  |> QuotationOption.changeset(Map.put(option_attrs, :quotation_id, quotation.id))
  |> Repo.insert!()
  
  IO.puts("✅ Opción creada: #{option.option_name} - $#{Decimal.to_string(option.final_price)}")
end)

# Mostrar estadísticas
IO.puts("\n📊 Estadísticas del Sistema:")
IO.puts("- Categorías de materiales: #{length(created_categories)}")
IO.puts("- Materiales disponibles: #{length(created_materials)}")
IO.puts("- Cotizaciones creadas: 1")
IO.puts("- Opciones de cotización: #{length(options_data)}")

# Calcular valor total del inventario
total_inventory_value = created_materials
|> Enum.map(fn material ->
  Decimal.mult(material.cost_per_unit, material.current_stock)
end)
|> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

IO.puts("- Valor total del inventario: $#{Decimal.to_string(total_inventory_value)}")

IO.puts("\n🎯 Funcionalidades Implementadas:")
IO.puts("✅ Gestión de categorías de materiales")
IO.puts("✅ Gestión de materiales con costos")
IO.puts("✅ Sistema de cotizaciones")
IO.puts("✅ Múltiples opciones de cotización")
IO.puts("✅ Cálculo automático de precios")
IO.puts("✅ Control de inventario")
IO.puts("✅ Números de cotización automáticos")

IO.puts("\n🚀 Próximos Pasos:")
IO.puts("1. Ejecutar migraciones: mix ecto.migrate")
IO.puts("2. Reiniciar servidor: mix phx.server")
IO.puts("3. Acceder a /quotations para probar el sistema")
IO.puts("4. Crear cotizaciones con diferentes materiales")
IO.puts("5. Ver opciones automáticas generadas")

IO.puts("\n✨ Sistema de Cotizaciones Listo para Demostración!") 