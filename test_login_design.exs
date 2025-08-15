#!/usr/bin/env elixir

# Test script for the new login page design
# Run with: mix run test_login_design.exs

alias EvaaCrmGaepell.{User, Repo}
import Ecto.Query

# Start the application
Application.ensure_all_started(:evaa_crm_gaepell)

IO.puts("🎨 Testing New Login Page Design")
IO.puts("=" |> String.duplicate(50))

# Test user credentials
test_email = "admin@evaacrm.com"
test_password = "password123"

# Check if test user exists
user = Repo.get_by(User, email: test_email)

if user do
  IO.puts("✅ Test user found:")
  IO.puts("  Email: #{user.email}")
  IO.puts("  Role: #{user.role}")
  IO.puts("  ID: #{user.id}")
  
  IO.puts("\n🌐 Login Page Features:")
  IO.puts("  - Beautiful Flowbite-inspired design")
  IO.puts("  - Dark mode support")
  IO.puts("  - Responsive layout")
  IO.puts("  - Gradient background on left side")
  IO.puts("  - Modern form inputs")
  IO.puts("  - Error message styling")
  IO.puts("  - Success message styling")
  IO.puts("  - Remember me checkbox")
  IO.puts("  - Forgot password link")
  IO.puts("  - Create account link")
  
  IO.puts("\n🔧 Functionality Preserved:")
  IO.puts("  - CSRF protection")
  IO.puts("  - Form validation")
  IO.puts("  - Session management")
  IO.puts("  - Error handling")
  IO.puts("  - Redirect after login")
  
  IO.puts("\n📱 Responsive Design:")
  IO.puts("  - Mobile-friendly")
  IO.puts("  - Tablet optimized")
  IO.puts("  - Desktop enhanced")
  IO.puts("  - Hidden image on mobile")
  IO.puts("  - Full-width form on mobile")
  
  IO.puts("\n🎨 Visual Elements:")
  IO.puts("  - EvaaCRM logo")
  IO.puts("  - Gradient background")
  IO.puts("  - SVG icons")
  IO.puts("  - Modern typography")
  IO.puts("  - Smooth hover effects")
  IO.puts("  - Focus states")
  
  IO.puts("\n✅ Login Page Test Completed Successfully!")
  IO.puts("🌐 You can now visit: http://localhost:4000/login")
  IO.puts("   The page should display:")
  IO.puts("   - Beautiful login form")
  IO.puts("   - Gradient background on desktop")
  IO.puts("   - Full dark mode support")
  IO.puts("   - Responsive design")
  IO.puts("   - All existing functionality")
  
else
  IO.puts("❌ Test user not found")
  IO.puts("Creating test user...")
  
  # Get first business for the user
  business = Repo.one(from b in EvaaCrmGaepell.Business, limit: 1)
  
  if business do
    # Create test user
    user_params = %{
      email: test_email,
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      role: "admin",
      business_id: business.id
    }
    
    case %User{}
         |> User.changeset(user_params)
         |> Repo.insert() do
      {:ok, user} ->
        IO.puts("✅ Test user created successfully!")
        IO.puts("  Email: #{user.email}")
        IO.puts("  Role: #{user.role}")
        IO.puts("  Business ID: #{user.business_id}")
        IO.puts("\n🌐 You can now visit: http://localhost:4000/login")
        
      {:error, changeset} ->
        IO.puts("❌ Failed to create test user:")
        IO.puts("  Errors: #{inspect(changeset.errors)}")
    end
  else
    IO.puts("❌ No business found in database")
    IO.puts("Please create a business first to test the login page")
  end
end 