#!/bin/bash

echo "=========================================="
echo "🔍 Checking users in database"
echo "=========================================="

echo ""
echo "Checking if admin user exists..."
mix run -e "
alias EvaaCrmGaepell.{Repo, User}
user = Repo.get_by(User, email: \"admin@eva.com\")
if user do
  IO.puts(\"✅ User found: #{user.email}\")
  IO.puts(\"   Role: #{user.role}\")
  IO.puts(\"   Business ID: #{user.business_id}\")
  if user.password_hash do
    IO.puts(\"   Password hash: EXISTS\")
  else
    IO.puts(\"   Password hash: MISSING\")
  end
else
  IO.puts(\"❌ User not found\")
end

IO.puts(\"\")
IO.puts(\"Total users in database:\")
count = Repo.aggregate(User, :count)
IO.puts(\"   #{count} users\")
"

echo ""
echo "=========================================="

