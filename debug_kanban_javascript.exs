#!/usr/bin/env elixir

# Debug script for Kanban JavaScript issues
# Run with: mix run debug_kanban_javascript.exs

IO.puts("=== DEBUGGING KANBAN JAVASCRIPT ISSUES ===")

# Load the application
Application.ensure_all_started(:evaa_crm_gaepell)

IO.puts("\n1. Checking if the server is running...")
IO.puts("   Make sure the server is running with: mix phx.server")
IO.puts("   Then open: http://localhost:4000/kanban")

IO.puts("\n2. JavaScript debugging steps:")
IO.puts("   a) Open browser console (F12)")
IO.puts("   b) Look for these messages:")
IO.puts("      - 'KanbanDragDrop hook mounted'")
IO.puts("      - 'Found columns with data-kanban-column: X'")
IO.puts("      - 'Creating sortable for column X'")
IO.puts("   c) If you don't see these messages, there's a JavaScript error")

IO.puts("\n3. Common JavaScript issues to check:")
IO.puts("   a) Sortable.js not loaded - check network tab for 404 errors")
IO.puts("   b) JavaScript syntax errors - check console for red errors")
IO.puts("   c) Hook not mounted - check if phx-hook='KanbanDragDrop' is present")
IO.puts("   d) Missing data attributes - check if columns have data-kanban-column")

IO.puts("\n4. HTML structure verification:")
IO.puts("   Check that the Kanban container has:")
IO.puts("   - phx-hook='KanbanDragDrop'")
IO.puts("   - data-kanban-column on each column")
IO.puts("   - data-status and data-workflow on each column")
IO.puts("   - .kanban-col-cards class on card containers")

IO.puts("\n5. Testing drag-and-drop manually:")
IO.puts("   a) Try to drag a lead card")
IO.puts("   b) Check if the card becomes semi-transparent (opacity: 0.5)")
IO.puts("   c) Check if you can drop it in another column")
IO.puts("   d) Check console for 'Sortable onEnd' messages")

IO.puts("\n6. Network debugging:")
IO.puts("   a) Open Network tab in browser dev tools")
IO.puts("   b) Try to drag a card")
IO.puts("   c) Look for WebSocket messages or HTTP requests")
IO.puts("   d) Check if 'kanban:move' events are being sent")

IO.puts("\n7. Server-side debugging:")
IO.puts("   Check server logs for:")
IO.puts("   - 'kanban:move event received'")
IO.puts("   - 'Lead X status field updated to: Y'")
IO.puts("   - 'Broadcast sent'")

IO.puts("\n8. Quick fix attempts:")
IO.puts("   a) Hard refresh the page (Ctrl+F5)")
IO.puts("   b) Clear browser cache")
IO.puts("   c) Try in incognito/private mode")
IO.puts("   d) Check if JavaScript is enabled")

IO.puts("\n9. Alternative debugging approach:")
IO.puts("   Add this to the browser console to test Sortable.js:")
IO.puts("   console.log('Sortable available:', typeof Sortable !== 'undefined')")
IO.puts("   console.log('Sortable version:', Sortable.version)")

IO.puts("\n10. Check if the issue is specific to leads:")
IO.puts("    Try dragging other items (tickets, activities) to see if the issue")
IO.puts("    is specific to leads or affects all drag-and-drop")

IO.puts("\n=== DEBUGGING COMPLETE ===")
IO.puts("If you're still having issues, please share:")
IO.puts("1. Browser console errors")
IO.puts("2. Network tab requests")
IO.puts("3. Server logs when trying to drag") 