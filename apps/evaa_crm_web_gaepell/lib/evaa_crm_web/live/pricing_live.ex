defmodule EvaaCrmWebGaepell.PricingLive do
  use EvaaCrmWebGaepell, :live_view
  alias EvaaCrmGaepell.{Repo, User}

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")
    current_user = if user_id, do: Repo.get(User, user_id), else: nil

    {:ok,
          socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Propuesta Comercial - E.V.A")
     |> assign(:selected_plan, nil)
     |> assign(:show_plan_details, false)
     |> assign(:show_contact_form, false)
     |> assign(:contact_form, %{
       name: "",
       email: "",
       company: "",
       phone: "",
       message: "",
       selected_plan: ""
     })
     |> assign(:pricing_plans, pricing_plans())
     |> assign(:features_included, features_included())
     |> assign(:timeline, timeline())
     |> assign(:guarantees, guarantees())
     |> assign(:first_client_benefits, first_client_benefits())
     |> assign(:comparison_data, comparison_data())}
  end

  @impl true
  def handle_event("select_plan", %{"plan" => plan}, socket) do
    {:noreply, assign(socket, :selected_plan, plan)}
  end

  @impl true
  def handle_event("show_plan_details", %{"plan" => plan}, socket) do
    {:noreply, assign(socket, :show_plan_details, true) |> assign(:selected_plan, plan)}
  end

  @impl true
  def handle_event("close_plan_details", _params, socket) do
    {:noreply, assign(socket, :show_plan_details, false)}
  end

  @impl true
  def handle_event("show_contact_form", _params, socket) do
    {:noreply, assign(socket, :show_contact_form, true)}
  end

  @impl true
  def handle_event("close_contact_form", _params, socket) do
    {:noreply, assign(socket, :show_contact_form, false)}
  end

  @impl true
  def handle_event("update_contact_form", %{"field" => field, "value" => value}, socket) do
    updated_form = Map.put(socket.assigns.contact_form, String.to_atom(field), value)
    {:noreply, assign(socket, :contact_form, updated_form)}
  end

  @impl true
  def handle_event("submit_contact_form", _params, socket) do
    # Aquí podrías enviar un email, guardar en base de datos, etc.
    {:noreply,
     socket
     |> put_flash(:info, "¡Gracias por tu interés! Te contactaremos pronto.")
     |> assign(:show_contact_form, false)
     |> assign(:contact_form, %{
       name: "",
       email: "",
       company: "",
       phone: "",
       message: "",
       selected_plan: ""
     })}
  end

  def pricing_plans do
    [
      %{
        id: "premium",
        name: "Plan Premium",
        subtitle: "Recomendado",
        price: 2500,
        original_price: 3000,
        discount: "20%",
        description: "Pago anticipado con descuento especial",
        features: [
          "Desarrollo más rápido",
          "Prioridad en el cronograma",
          "Soporte premium incluido",
          "Capacitación personalizada",
          "Soporte técnico lifetime",
          "Actualizaciones de por vida"
        ],
        payment_structure: [
          %{label: "40% Anticipo", amount: 1000, description: "Al iniciar el proyecto"},
          %{label: "60% Final", amount: 1500, description: "Al entregar el sistema"}
        ],
        color: "blue",
        badge: "Primer Cliente",
        recommended: true
      },
      %{
        id: "standard",
        name: "Plan Estándar",
        subtitle: "Tradicional",
        price: 3000,
        original_price: 3000,
        discount: nil,
        description: "Pagos distribuidos durante el desarrollo",
        features: [
          "Pagos distribuidos",
          "Menor riesgo financiero",
          "Seguimiento de progreso",
          "Capacitación del equipo",
          "Soporte técnico lifetime",
          "Actualizaciones de por vida"
        ],
        payment_structure: [
          %{label: "30% Inicial", amount: 900, description: "Al iniciar el proyecto"},
          %{label: "40% Progreso", amount: 1200, description: "Al 50% del desarrollo"},
          %{label: "30% Final", amount: 900, description: "Al entregar el sistema"}
        ],
        color: "green",
        badge: "Más Flexible",
        recommended: false
      },
      %{
        id: "flexible",
        name: "Plan Flexible",
        subtitle: "Accesible",
        price: 3200,
        original_price: 3200,
        discount: nil,
        description: "Plan de pagos mensuales sin intereses",
        features: [
          "Mínima inversión inicial",
          "8 pagos mensuales",
          "Sin intereses adicionales",
          "Flexibilidad total",
          "Soporte técnico lifetime",
          "Actualizaciones de por vida"
        ],
        payment_structure: [
          %{label: "Pago Inicial", amount: 500, description: "Al iniciar el proyecto"},
          %{label: "8 Cuotas Mensuales", amount: 337.5, description: "Pagos de $337.50 USD"}
        ],
        color: "purple",
        badge: "Más Accesible",
        recommended: false
      }
    ]
  end

  def features_included do
    [
      %{
        category: "Gestión de Flotas",
        icon: "🚛",
        items: [
          "Control de vehículos y equipos",
          "Mantenimiento preventivo",
          "Historial de servicios",
          "Gestión de combustible",
          "Reportes de eficiencia"
        ]
      },
      %{
        category: "Sistema de Cotizaciones",
        icon: "📋",
        items: [
          "Generación automática de cotizaciones",
          "Plantillas personalizables",
          "Seguimiento de propuestas",
          "Gestión de clientes",
          "Reportes de ventas"
        ]
      },
      %{
        category: "Dashboard Analítico",
        icon: "📊",
        items: [
          "Métricas en tiempo real",
          "Gráficos de rendimiento",
          "Reportes personalizables",
          "Exportación de datos"
        ]
      },
      %{
        category: "Gestión de Usuarios",
        icon: "👥",
        items: [
          "Roles y permisos",
          "Acceso móvil",
          "Notificaciones automáticas",
          "Auditoría de actividades"
        ]
      }
    ]
  end

  def timeline do
    [
      %{
        index: 0,
        phase: "Fase 1",
        duration: "2 semanas",
        title: "Configuración Inicial",
        description: "Configuración inicial, implementación básica y pruebas de funcionalidad"
      },
      %{
        index: 1,
        phase: "Fase 2",
        duration: "2 semanas",
        title: "Desarrollo Avanzado",
        description: "Desarrollo de módulos avanzados, integración de reportes y optimización"
      },
      %{
        index: 2,
        phase: "Fase 3",
        duration: "1 semana",
        title: "Entrega Final",
        description: "Pruebas finales, capacitación y entrega del sistema completo"
      }
    ]
  end

  def guarantees do
    [
      "100% funcional o devolución del dinero",
      "Soporte técnico lifetime sin costo adicional",
      "Actualizaciones gratuitas de por vida",
      "Capacitación del personal lifetime",
      "Migración de datos sin costo adicional",
      "Propiedad completa del código fuente",
      "Propiedad total del sistema implementado",
      "Licencia perpetua sin restricciones"
    ]
  end

  def first_client_benefits do
    [
      "🎯 Capacitación del personal de por vida",
      "🔧 Mantenimiento y soporte técnico lifetime",
      "📈 Actualizaciones gratuitas de por vida",
      "🎨 Personalización completa del sistema",
      "📱 Soporte prioritario 24/7",
      "📊 Reportes personalizados sin costo adicional"
    ]
  end

    def comparison_data do
    [
      %{
        agency: "Agencias Tradicionales",
        price: "8,000 - 15,000 USD",
        timeline: "6-12 meses",
        support: "Limitado",
        customization: "Básica",
        maintenance: "Mensual",
        features: [
          "Sistema básico",
          "Soporte por email",
          "Actualizaciones pagadas",
          "Capacitación básica"
        ]
      },
      %{
        agency: "Consultoras Grandes",
        price: "25,000 - 50,000 USD",
        timeline: "12-18 meses",
        support: "Premium",
        customization: "Completa",
        maintenance: "Anual",
        features: [
          "Sistema complejo",
          "Soporte telefónico",
          "Actualizaciones incluidas",
          "Capacitación completa"
        ]
      },
      %{
        agency: "E.V.A (Tu Opción)",
        price: "2,500 - 3,200 USD",
        timeline: "5 semanas",
        support: "Lifetime",
        customization: "Completa",
        maintenance: "Gratuito",
        features: [
          "Sistema moderno y ágil",
          "Soporte 24/7",
          "Actualizaciones gratuitas",
          "Capacitación lifetime"
        ]
      }
    ]
  end

  def get_plan_details(plan_id) do
    case plan_id do
      "premium" -> %{
        name: "Plan Premium",
        subtitle: "Recomendado para Grupo Gaepell",
        description: "El plan más conveniente con pago anticipado y descuento especial. Ideal para empresas que quieren optimizar costos y obtener el máximo valor.",
        benefits: [
          "💰 Ahorro inmediato de $500 USD con descuento del 20%",
          "⚡ Desarrollo prioritario - Tu proyecto será el primero en la cola",
          "🎯 Capacitación personalizada para todo tu equipo",
          "🔧 Soporte premium con respuesta en menos de 2 horas",
          "📈 Actualizaciones gratuitas de por vida",
          "🏆 Propiedad total del código fuente y sistema"
        ],
        why_choose: [
          "Mejor relación precio-beneficio del mercado",
          "Desarrollo más rápido con prioridad absoluta",
          "Máximo ahorro con el descuento especial",
          "Beneficios exclusivos de primer cliente"
        ],
        timeline_details: [
          "Semana 1-2: Configuración inicial y análisis de necesidades específicas",
          "Semana 3-4: Desarrollo avanzado con entregas semanales",
          "Semana 5: Pruebas finales, capacitación y entrega completa"
        ],
        investment_breakdown: [
          "Inversión inicial: $1,000 USD (40%)",
          "Inversión final: $1,500 USD (60%)",
          "Ahorro total: $500 USD vs precio normal",
          "ROI estimado: 300% en el primer año"
        ]
      }
      
      "standard" -> %{
        name: "Plan Estándar",
        subtitle: "Flexibilidad y control financiero",
        description: "Plan tradicional con pagos distribuidos que te permite mantener el control de tu flujo de caja mientras desarrollamos tu sistema.",
        benefits: [
          "💳 Pagos distribuidos sin intereses adicionales",
          "📊 Seguimiento detallado del progreso del desarrollo",
          "👥 Capacitación completa para todo el equipo",
          "🛠️ Soporte técnico lifetime incluido",
          "🔄 Actualizaciones gratuitas de por vida",
          "🏆 Propiedad total del código fuente y sistema"
        ],
        why_choose: [
          "Menor impacto en el flujo de caja",
          "Seguimiento transparente del progreso",
          "Flexibilidad en los pagos",
          "Misma calidad premium con pagos distribuidos"
        ],
        timeline_details: [
          "Semana 1-2: Configuración inicial y primer pago",
          "Semana 3-4: Desarrollo con entregas parciales y segundo pago",
          "Semana 5: Finalización, capacitación y pago final"
        ],
        investment_breakdown: [
          "Pago inicial: $900 USD (30%)",
          "Pago progreso: $1,200 USD (40%)",
          "Pago final: $900 USD (30%)",
          "Total: $3,000 USD sin intereses"
        ]
      }
      
      "flexible" -> %{
        name: "Plan Flexible",
        subtitle: "Mínima inversión inicial",
        description: "Plan diseñado para empresas que quieren empezar con la mínima inversión posible, pagando en cuotas mensuales sin intereses.",
        benefits: [
          "💸 Mínima inversión inicial de solo $500 USD",
          "📅 8 pagos mensuales de $337.50 USD sin intereses",
          "🚀 Puedes empezar inmediatamente con tu proyecto",
          "👨‍💼 Capacitación lifetime para todo el personal",
          "🔧 Mantenimiento y soporte técnico lifetime",
          "🏆 Propiedad total del código fuente y sistema"
        ],
        why_choose: [
          "Mínima barrera de entrada",
          "Flexibilidad total en los pagos",
          "Sin intereses ni cargos ocultos",
          "Misma calidad premium con pagos flexibles"
        ],
        timeline_details: [
          "Semana 1: Inicio inmediato con pago inicial",
          "Semana 2-4: Desarrollo continuo con entregas semanales",
          "Semana 5: Finalización y capacitación completa"
        ],
        investment_breakdown: [
          "Pago inicial: $500 USD",
          "8 cuotas mensuales: $337.50 USD cada una",
          "Total: $3,200 USD sin intereses",
          "Primera cuota: 30 días después del inicio"
        ]
      }
      
      _ -> nil
    end
  end
end 