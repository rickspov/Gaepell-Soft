# Seeds para workflows por defecto
alias EvaaCrmGaepell.WorkflowService

# Cambia el business_id si es necesario
business_id = 1

IO.puts("Creando workflows por defecto para business_id=#{business_id} ...")
WorkflowService.create_default_workflows(business_id)
IO.puts("✅ Workflows y estados creados exitosamente.") 