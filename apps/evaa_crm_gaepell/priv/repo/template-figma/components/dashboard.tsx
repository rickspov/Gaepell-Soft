import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { StatusBadge } from "./status-badge";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { 
  Truck,
  Wrench,
  CheckCircle,
  AlertTriangle,
  Plus,
  Eye,
  TrendingUp,
  TrendingDown,
  Activity,
  Calendar
} from "lucide-react";

// Mock data
const statsData = [
  {
    title: "Camiones Activos",
    value: "24",
    description: "En operación",
    icon: Truck,
    trend: "+2 este mes",
    trendUp: true,
    gradient: "gradient-primary"
  },
  {
    title: "Tickets Pendientes",
    value: "12",
    description: "Requieren atención",
    icon: Wrench,
    trend: "-3 esta semana",
    trendUp: false,
    gradient: "gradient-warning"
  },
  {
    title: "Mantenimientos Completados",
    value: "156",
    description: "Este mes",
    icon: CheckCircle,
    trend: "+18% vs mes anterior",
    trendUp: true,
    gradient: "gradient-success"
  },
  {
    title: "Alertas Críticas",
    value: "3",
    description: "Requieren acción inmediata",
    icon: AlertTriangle,
    trend: "Sin cambios",
    trendUp: null,
    gradient: "gradient-danger"
  }
];

const recentTrucks = [
  {
    id: "TRK-001",
    plate: "ABC-123",
    model: "Volvo FH 460",
    status: "active",
    lastMaintenance: "2024-01-15",
    nextMaintenance: "2024-04-15",
    image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
  },
  {
    id: "TRK-002",
    plate: "DEF-456",
    model: "Mercedes Actros 1845",
    status: "maintenance",
    lastMaintenance: "2024-01-10",
    nextMaintenance: "2024-04-10",
    image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
  },
  {
    id: "TRK-003",
    plate: "GHI-789",
    model: "Scania R 450",
    status: "active",
    lastMaintenance: "2024-01-08",
    nextMaintenance: "2024-04-08",
    image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
  },
];

const recentTickets = [
  {
    id: "TCK-001",
    truck: "ABC-123",
    issue: "Cambio de aceite",
    status: "pending" as const,
    priority: "medium",
    createdAt: "2024-01-20"
  },
  {
    id: "TCK-002",
    truck: "DEF-456",
    issue: "Reparación frenos",
    status: "in-progress" as const,
    priority: "high",
    createdAt: "2024-01-19"
  },
  {
    id: "TCK-003",
    truck: "GHI-789",
    issue: "Revisión general",
    status: "completed" as const,
    priority: "low",
    createdAt: "2024-01-18"
  }
];

interface DashboardProps {
  onNavigate?: (section: string, id?: string) => void;
}

export function Dashboard({ onNavigate }: DashboardProps) {
  return (
    <div className="space-y-8">
      {/* Welcome Header */}
      <div className="text-center py-8">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-slate-900 via-amber-600 to-slate-900 dark:from-slate-100 dark:via-yellow-400 dark:to-slate-100 bg-clip-text text-transparent mb-3">
          EvaCRM - Eficiencia Virtual Asistida
        </h1>
        <p className="text-lg text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
          Gestiona tu flota de manera inteligente con herramientas avanzadas de monitoreo y mantenimiento.
        </p>
      </div>

      {/* Stats Cards Modernos */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        {statsData.map((stat, index) => (
          <Card key={index} className="relative overflow-hidden hover-lift border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
            <div className={`absolute inset-0 ${stat.gradient} opacity-10`}></div>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3 relative z-10">
              <div>
                <CardTitle className="text-sm font-medium text-slate-600 dark:text-slate-400">{stat.title}</CardTitle>
                <div className="text-3xl font-bold text-slate-900 dark:text-slate-100 mt-2">{stat.value}</div>
              </div>
              <div className={`h-12 w-12 rounded-xl ${stat.gradient} flex items-center justify-center shadow-lg`}>
                <stat.icon className="h-6 w-6 text-white" />
              </div>
            </CardHeader>
            <CardContent className="relative z-10">
              <p className="text-xs text-slate-500 dark:text-slate-400 mb-2">{stat.description}</p>
              <div className="flex items-center gap-1 text-xs">
                {stat.trendUp === true && <TrendingUp className="h-3 w-3 text-green-600" />}
                {stat.trendUp === false && <TrendingDown className="h-3 w-3 text-red-600" />}
                {stat.trendUp === null && <Activity className="h-3 w-3 text-slate-500 dark:text-slate-400" />}
                <span className={`font-medium ${
                  stat.trendUp === true ? 'text-green-600' : 
                  stat.trendUp === false ? 'text-red-600' : 'text-slate-500 dark:text-slate-400'
                }`}>
                  {stat.trend}
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
        {/* Recent Trucks */}
        <Card className="xl:col-span-2 border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
          <CardHeader className="bg-gradient-to-r from-slate-50 to-blue-50 dark:from-slate-800/50 dark:to-blue-900/20 rounded-t-xl">
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Camiones Recientes</CardTitle>
                <CardDescription className="text-slate-600 dark:text-slate-400">Actividad reciente de la flota</CardDescription>
              </div>
              <Button 
                onClick={() => onNavigate?.("trucks")}
                className="gradient-primary text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200"
              >
                Ver todos
              </Button>
            </div>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-4">
              {recentTrucks.map((truck) => (
                <div key={truck.id} className="flex items-center space-x-4 p-4 border border-slate-200/60 dark:border-slate-700/60 rounded-xl hover:shadow-md transition-all duration-200 hover-lift bg-white dark:bg-slate-800/50">
                  <ImageWithFallback
                    src={truck.image}
                    alt={truck.model}
                    className="h-16 w-16 rounded-xl object-cover border-2 border-white dark:border-slate-700 shadow-md"
                  />
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-1">
                      <h4 className="font-semibold text-slate-900 dark:text-slate-100">{truck.plate}</h4>
                      <Badge 
                        variant={truck.status === "active" ? "default" : "secondary"}
                        className={truck.status === "active" 
                          ? "gradient-success text-white border-0" 
                          : "bg-orange-100 dark:bg-orange-900/50 text-orange-700 dark:text-orange-300 border-orange-200 dark:border-orange-800"
                        }
                      >
                        {truck.status === "active" ? "Activo" : "Mantenimiento"}
                      </Badge>
                    </div>
                    <p className="text-sm text-slate-600 dark:text-slate-400 font-medium">{truck.model}</p>
                    <div className="flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400 mt-1">
                      <Calendar className="h-3 w-3" />
                      <span>Último mantenimiento: {new Date(truck.lastMaintenance).toLocaleDateString('es-ES')}</span>
                    </div>
                  </div>
                  <Button 
                    variant="outline" 
                    size="sm" 
                    onClick={() => onNavigate?.("trucks", truck.id)}
                    className="border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                  >
                    <Eye className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Recent Tickets */}
        <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
          <CardHeader className="bg-gradient-to-r from-slate-50 to-purple-50 dark:from-slate-800/50 dark:to-purple-900/20 rounded-t-xl">
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Tickets Recientes</CardTitle>
                <CardDescription className="text-slate-600 dark:text-slate-400">Últimos reportes</CardDescription>
              </div>
              <Button 
                size="sm" 
                onClick={() => onNavigate?.("tickets")}
                className="gradient-primary text-white border-0 shadow-md hover:shadow-lg transition-all duration-200"
              >
                <Plus className="h-4 w-4" />
              </Button>
            </div>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-4">
              {recentTickets.map((ticket) => (
                <div key={ticket.id} className="space-y-3 p-4 border border-slate-200/60 dark:border-slate-700/60 rounded-xl hover:shadow-md transition-all duration-200 hover-lift bg-white dark:bg-slate-800/50">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-slate-900 dark:text-slate-100 text-sm">{ticket.id}</span>
                    <StatusBadge status={ticket.status} />
                  </div>
                  <p className="text-sm font-medium text-slate-800 dark:text-slate-200">{ticket.issue}</p>
                  <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                    <span>Camión: <span className="font-medium text-slate-700 dark:text-slate-300">{ticket.truck}</span></span>
                    <span>{new Date(ticket.createdAt).toLocaleDateString('es-ES')}</span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
        <CardHeader className="bg-gradient-to-r from-slate-50 to-green-50 dark:from-slate-800/50 dark:to-green-900/20 rounded-t-xl">
          <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Acciones Rápidas</CardTitle>
          <CardDescription className="text-slate-600 dark:text-slate-400">Herramientas principales para gestión diaria</CardDescription>
        </CardHeader>
        <CardContent className="p-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Button 
              className="h-24 flex-col gap-3 gradient-primary text-white border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover-lift" 
              onClick={() => onNavigate?.("tickets")}
            >
              <Plus className="h-6 w-6" />
              <span className="font-medium">Crear Ticket</span>
            </Button>
            <Button 
              variant="outline" 
              className="h-24 flex-col gap-3 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 hover:shadow-lg transition-all duration-300 hover-lift bg-white dark:bg-slate-800/50" 
              onClick={() => onNavigate?.("trucks")}
            >
              <Truck className="h-6 w-6 text-blue-600" />
              <span className="font-medium text-slate-700 dark:text-slate-300">Registrar Camión</span>
            </Button>
            <Button 
              variant="outline" 
              className="h-24 flex-col gap-3 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 hover:shadow-lg transition-all duration-300 hover-lift bg-white dark:bg-slate-800/50" 
              onClick={() => onNavigate?.("evaluations")}
            >
              <CheckCircle className="h-6 w-6 text-green-600" />
              <span className="font-medium text-slate-700 dark:text-slate-300">Nueva Evaluación</span>
            </Button>
            <Button 
              variant="outline" 
              className="h-24 flex-col gap-3 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 hover:shadow-lg transition-all duration-300 hover-lift bg-white dark:bg-slate-800/50" 
              onClick={() => onNavigate?.("documents")}
            >
              <AlertTriangle className="h-6 w-6 text-orange-600" />
              <span className="font-medium text-slate-700 dark:text-slate-300">Ver Reportes</span>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}