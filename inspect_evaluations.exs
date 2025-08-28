alias EvaaCrmGaepell.{Repo, Evaluation}

evaluation4 = Repo.get(Evaluation, 4)
evaluation5 = Repo.get(Evaluation, 5)

IO.puts("=== Evaluación #4 ===")
IO.inspect(evaluation4.photos, label: "Photos")

IO.puts("\n=== Evaluación #5 ===")
IO.inspect(evaluation5.photos, label: "Photos")

# También inspeccionar la estructura completa
IO.puts("\n=== Estructura completa Evaluación #4 ===")
IO.inspect(evaluation4, label: "Evaluation #4")

IO.puts("\n=== Estructura completa Evaluación #5 ===")
IO.inspect(evaluation5, label: "Evaluation #5")


