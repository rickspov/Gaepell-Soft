#!/usr/bin/env elixir

# Test script to verify the improved login page design
# Run with: mix run test_login_design_improved.exs

# Start the application
Application.ensure_all_started(:evaa_crm_gaepell)

# Test the improved login page design
IO.puts("🧪 Testing improved login page design...")

# Test 1: Check if the page loads with new styling
IO.puts("\n1. Testing login page accessibility...")
try do
  # This would normally test the actual page, but for now we'll just verify the file exists
  login_file = "apps/evaa_crm_web_gaepell/lib/evaa_crm_web/controllers/session_html/new.html.heex"
  
  if File.exists?(login_file) do
    content = File.read!(login_file)
    
    # Check for improved styling elements
    improvements = [
      {"Better spacing", "px-8 pt-12"},
      {"Improved logo layout", "flex-col justify-center items-center"},
      {"EVA branding", "Eficiencia Virtual Asistida"},
      {"Enhanced padding", "p-8 space-y-10"},
      {"Better typography", "tracking-wide"},
      {"Rounded corners", "rounded-xl"},
      {"Enhanced shadows", "shadow-2xl"},
      {"Larger form elements", "p-4"},
      {"Better button styling", "py-4 px-6"}
    ]
    
    IO.puts("✅ Login page file exists")
    
    improvements
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
  e -> IO.puts("❌ Error testing login page: #{inspect(e)}")
end

# Test 2: Verify EVA branding elements
IO.puts("\n2. Testing EVA branding elements...")
try do
  login_file = "apps/evaa_crm_web_gaepell/lib/evaa_crm_web/controllers/session_html/new.html.heex"
  content = File.read!(login_file)
  
  branding_elements = [
    {"EVA logo", "logoeva1.png"},
    {"EVA text", "EVA"},
    {"Full name", "Eficiencia Virtual Asistida"},
    {"Logo size", "h-16"},
    {"Branding layout", "flex-col"}
  ]
  
  branding_elements
  |> Enum.each(fn {description, element} ->
    if String.contains?(content, element) do
      IO.puts("✅ #{description}: #{element}")
    else
      IO.puts("❌ #{description}: #{element} - NOT FOUND")
    end
  end)
  
rescue
  e -> IO.puts("❌ Error testing branding: #{inspect(e)}")
end

# Test 3: Check for improved spacing and typography
IO.puts("\n3. Testing improved spacing and typography...")
try do
  login_file = "apps/evaa_crm_web_gaepell/lib/evaa_crm_web/controllers/session_html/new.html.heex"
  content = File.read!(login_file)
  
  spacing_improvements = [
    {"Letter spacing", "tracking-wide"},
    {"Enhanced padding", "p-8"},
    {"Better margins", "mb-12"},
    {"Improved form spacing", "space-y-8"},
    {"Larger text", "text-3xl"},
    {"Better button padding", "py-4 px-6"},
    {"Enhanced input padding", "p-4"}
  ]
  
  spacing_improvements
  |> Enum.each(fn {description, class} ->
    if String.contains?(content, class) do
      IO.puts("✅ #{description}: #{class}")
    else
      IO.puts("❌ #{description}: #{class} - NOT FOUND")
    end
  end)
  
rescue
  e -> IO.puts("❌ Error testing spacing: #{inspect(e)}")
end

IO.puts("\n🎉 Login page design improvement test completed!")
IO.puts("\n📝 Summary of improvements:")
IO.puts("   • Better spacing and padding throughout")
IO.puts("   • Enhanced typography with letter spacing")
IO.puts("   • EVA branding with logo and full name")
IO.puts("   • Improved form elements with larger padding")
IO.puts("   • Enhanced visual hierarchy")
IO.puts("   • Better rounded corners and shadows") 