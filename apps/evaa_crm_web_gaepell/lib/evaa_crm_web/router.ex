defmodule EvaaCrmWebGaepell.Router do
  use EvaaCrmWebGaepell, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EvaaCrmWebGaepell.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug EvaaCrmWebGaepell.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health check endpoint - minimal pipeline, no auth, no CSRF
  scope "/", EvaaCrmWebGaepell do
    # Health check with minimal pipeline
    get "/health", HealthController, :check
  end

  scope "/", EvaaCrmWebGaepell do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # Serve uploaded files
  scope "/uploads", EvaaCrmWebGaepell do
    pipe_through :browser
    
    get "/evaluations/*path", UploadController, :evaluation_photo
    get "/tickets/*path", UploadController, :ticket_attachment
    get "/maintenance/*path", UploadController, :maintenance_photo
    get "/documents/*path", UploadController, :document_file
    get "/wizard/*path", UploadController, :wizard_file
  end

  # Download generated files
  scope "/downloads", EvaaCrmWebGaepell do
    pipe_through :browser
    
    get "/:document_id/:filename", DownloadController, :document_zip
  end

  scope "/", EvaaCrmWebGaepell do
    pipe_through [:browser, :auth]

    # Dashboard principal como LiveView para usar el layout con sidebar
    live "/", KanbanLive
    
    # MVP LiveView routes
    live "/agenda", AgendaLive
    live "/crm", CrmLive
    live "/prospectos", LeadsLive
    live "/doctors", CompaniesLive
    live "/doctors/:id", DoctorProfileLive
    live "/especialistas/:id", SpecialistProfileLive
    live "/pacientes/:id", PatientProfileLive
    live "/analytics", AnalyticsLive
    live "/billing", BillingLive
    live "/inventory", InventoryLive
    live "/cash", CashDeskLive
    live "/users", UsersLive
    live "/trucks", TrucksLive
    live "/trucks/:id", TruckProfileLive
    live "/maintenance", MaintenanceTicketsLive
    live "/maintenance/:id", MaintenanceTicketsLive
    live "/tickets/:id", TicketDetailLive
    live "/logs/:entity_type/:entity_id", ActivityLogsLive
    live "/checkin", TicketWizardLive
    live "/checkin-wizard", CheckinWizardLive
    live "/maintenance-checkin-wizard", MaintenanceCheckinWizardLive
    live "/tickets", TicketsLive
    get "/evaluations", RedirectController, :to_evaluations_tab
    live "/documents", DocumentsLive
    live "/feedback", FeedbackLive
    live "/checkout", MaintenanceCheckoutLive
    live "/quotations", QuotationsLive
    live "/quotations/:id", QuotationsLive
    live "/pricing", PricingLive
    live "/symasoft-integration", SymasoftIntegrationLive
    live "/production-orders", ProductionOrdersLive
    live "/production-orders/:id", ProductionOrderDetailLive
    
    # API para sincronización offline
    post "/api/sync", SyncController, :sync
  end

  # Other scopes may use custom stacks.
  # scope "/api", EvaaCrmWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:evaa_crm_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EvaaCrmWebGaepell.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
