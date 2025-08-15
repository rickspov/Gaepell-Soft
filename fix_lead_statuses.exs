import Ecto.Query
alias EvaaCrmGaepell.{Repo, Lead}

valid_statuses = ["new", "contacted", "qualified", "converted", "lost"]

# 1. Actualizar 'proposal' a 'qualified'
proposal_leads = Repo.all(from l in Lead, where: l.status == "proposal")
Enum.each(proposal_leads, fn lead ->
  Lead.changeset(lead, %{status: "qualified"}) |> Repo.update!()
  IO.puts("Lead ##{lead.id} actualizado de 'proposal' a 'qualified'")
end)

# 2. Actualizar cualquier otro estado inválido a 'new'
invalid_leads = Repo.all(from l in Lead, where: l.status not in ^valid_statuses)
Enum.each(invalid_leads, fn lead ->
  Lead.changeset(lead, %{status: "new"}) |> Repo.update!()
  IO.puts("Lead ##{lead.id} actualizado de '#{lead.status}' a 'new'")
end)

IO.puts("\nActualización completada.") 