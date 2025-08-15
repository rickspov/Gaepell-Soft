#!/usr/bin/env elixir

# Test script to verify the improved padding in the login form area
# Run with: mix run test_login_padding_improved.exs

# Start the application
Application.ensure_all_started(:evaa_crm_gaepell)

# Test the improved login form padding
IO.puts("🧪 Testing improved login form padding...")

# Test 1: Check if the form area has better padding
IO.puts("\n1. Testing form area padding improvements...")
try do
  login_file = "apps/evaa_crm_web_gaepell/lib/evaa_crm_web/controllers/session_html/new.html.heex"
  
  if File.exists?(login_file) do
    content = File.read!(login_file)
    
    # Check for improved padding elements
    padding_improvements = [
      {"Form container padding", "p-12 space-y-12"},
      {"Large screen padding", "lg:p-24"},
      {"Small screen padding", "sm:p-16"},
      {"Form spacing", "space-y-10"},
      {"Input padding", "p-5"},
      {"Button padding", "py-5 px-8"},
      {"Label margins", "mb-4"},
      {"Additional spacing", "pt-4"},
      {"Button top margin", "mt-8"}
    ]
    
    IO.puts("✅ Login page file exists")
    
    padding_improvements
    |> Enum.each(fn {description, class} ->
      if String.contains?(content, class) do
        IO.puts("✅ #{description}: #{class}")
      else
        IO.puts("❌ #{description}: #{class} - NOT FOUND")
      end
    end)
    
  else
    IO.puts("❌ Login page file not found")
  end
  
rescue
  e -> IO.puts("❌ Error testing padding: #{inspect(e)}")
end

# Test 2: Verify specific spacing improvements
IO.puts("\n2. Testing specific spacing improvements...")
try do
  login_file = "apps/evaa_crm_web_gaepell/lib/evaa_crm_web/controllers/session_html/new.html.heex"
  content = File.read!(login_file)
  
  spacing_elements = [
    {"Form container", "p-12 space-y-12 w-full sm:p-16 lg:p-24 lg:py-8"},
    {"Input fields", "p-5"},
    {"Labels", "mb-4"},
    {"Button", "py-5 px-8"},
    {"Checkbox area", "pt-4"},
    {"Bottom text", "pt-4"}
  ]
  
  spacing_elements
  |> Enum.each(fn {description, element} ->
    if String.contains?(content, element) do
      IO.puts("✅ #{description}: #{element}")
    else
      IO.puts("❌ #{description}: #{element} - NOT FOUND")
    end
  end)
  
rescue
  e -> IO.puts("❌ Error testing spacing: #{inspect(e)}")
end

# Test 3: Check for better visual hierarchy
IO.puts("\n3. Testing improved visual hierarchy...")
try do
  login_file = "apps/evaa_crm_web_gaepell/lib/evaa_crm_web/controllers/session_html/new.html.heex"
  content = File.read!(login_file)
  
  hierarchy_improvements = [
    {"Better form spacing", "mt-12 space-y-10"},
    {"Enhanced margins", "mb-8"},
    {"Button spacing", "mt-8"},
    {"Additional padding", "pt-4"}
  ]
  
  hierarchy_improvements
  |> Enum.each(fn {description, class} ->
    if String.contains?(content, class) do
      IO.puts("✅ #{description}: #{class}")
    else
      IO.puts("❌ #{description}: #{class} - NOT FOUND")
    end
  end)
  
rescue
  e -> IO.puts("❌ Error testing hierarchy: #{inspect(e)}")
end

IO.puts("\n🎉 Login form padding improvement test completed!")
IO.puts("\n📝 Summary of padding improvements:")
IO.puts("   • Increased form container padding from p-8 to p-12")
IO.puts("   • Enhanced spacing between elements from space-y-8 to space-y-10")
IO.puts("   • Larger input padding from p-4 to p-5")
IO.puts("   • Better button padding from py-4 px-6 to py-5 px-8")
IO.puts("   • Improved margins and spacing throughout")
IO.puts("   • Added additional padding for better visual breathing room") 