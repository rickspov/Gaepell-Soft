import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Textarea } from "./ui/textarea";
import { Input } from "./ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Separator } from "./ui/separator";
import { Slider } from "./ui/slider";
import { Progress } from "./ui/progress";
import { StatusBadge } from "./status-badge";
import { EditTicketModal } from "./edit-ticket-modal";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { toast } from "sonner@2.0.3";
import { 
  ArrowLeft,
  Calendar,
  Clock,
  User,
  Truck,
  MapPin,
  DollarSign,
  FileText,
  Image as ImageIcon,
  MessageSquare,
  Edit,
  Save,
  X,
  CheckCircle,
  AlertTriangle,
  Wrench,
  Shield,
  Camera,
  Download,
  Upload,
  Phone,
  Mail,
  Settings,
  Activity,
  Timer,
  TrendingUp,
  TrendingDown
} from "lucide-react";

// Mock data para diferentes tipos de tickets
const ticketData: Record<string, any> = {
  "MNT-001": {
    id: "MNT-001",
    type: "maintenance",
    title: "Cambio de aceite y filtros",
    status: "in-progress" as const,
    priority: "medium",
    description: "Mantenimiento preventivo programado para cambio de aceite motor, filtro de aceite y filtro de aire según cronograma de mantenimiento.",
    truck: {
      id: "TRK-001",
      plate: "ABC-123",
      model: "Volvo FH 460",
      year: 2020,
      mileage: 145000,
      image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
    },
    reportedBy: {
      name: "Supervisor Pérez",
      role: "Supervisor de Flota",
      contact: "supervisor.perez@empresa.com",
      phone: "+1234567890"
    },
    assignedTo: {
      name: "Carlos García",
      role: "Técnico Mecánico",
      contact: "carlos.garcia@empresa.com",
      phone: "+1234567891"
    },
    location: "Bay 1 - Taller Principal",
    createdAt: "2024-01-20T10:30:00",
    scheduledDate: "2024-01-22T08:00:00",
    dueDate: "2024-01-22T17:00:00",
    startedAt: "2024-01-22T08:15:00",
    estimatedCost: 1250.00,
    actualCost: 1180.00,
    estimatedHours: 4,
    actualHours: 2.5,
    progress: 65,
    parts: [
      { name: "Aceite 15W40 20L", quantity: 1, cost: 120.00, status: "used" },
      { name: "Filtro aceite", quantity: 1, cost: 45.00, status: "used" },
      { name: "Filtro aire", quantity: 1, cost: 85.00, status: "pending" }
    ],
    attachments: [
      { name: "checklist_mantenimiento.pdf", type: "pdf", size: "2.4 MB", url: "#" },
      { name: "foto_antes.jpg", type: "image", size: "1.8 MB", url: "https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=400" },
      { name: "foto_proceso.jpg", type: "image", size: "2.1 MB", url: "https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400" }
    ],
    timeline: [
      { date: "2024-01-20T10:30:00", event: "Ticket creado", user: "Supervisor Pérez", type: "created" },
      { date: "2024-01-21T14:00:00", event: "Asignado a técnico", user: "Sistema", type: "assigned" },
      { date: "2024-01-22T08:15:00", event: "Trabajo iniciado", user: "Carlos García", type: "started" },
      { date: "2024-01-22T10:30:00", event: "Progreso actualizado - 40%", user: "Carlos García", type: "progress" },
      { date: "2024-01-22T13:45:00", event: "Progreso actualizado - 65%", user: "Carlos García", type: "progress" }
    ],
    comments: [
      {
        id: 1,
        user: "Carlos García",
        role: "Técnico",
        date: "2024-01-22T10:30:00",
        message: "Aceite drenado correctamente. Filtro de aceite reemplazado. Procediendo con filtro de aire.",
        type: "update"
      },
      {
        id: 2,
        user: "Supervisor Pérez",
        role: "Supervisor",
        date: "2024-01-22T11:00:00",
        message: "Perfecto, mantener el cronograma.",
        type: "comment"
      }
    ]
  },
  "EVL-001": {
    id: "EVL-001",
    type: "evaluation",
    title: "Evaluación de daños por colisión frontal",
    status: "pending" as const,
    priority: "high",
    severity: "high",
    description: "Evaluación completa de daños ocasionados por colisión frontal ocurrida en ruta principal. Se requiere inspección detallada de motor, sistema de dirección y estructura frontal.",
    truck: {
      id: "TRK-001",
      plate: "ABC-123",
      model: "Volvo FH 460",
      year: 2020,
      mileage: 145000,
      image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
    },
    reportedBy: {
      name: "Inspector Martínez",
      role: "Inspector de Seguridad",
      contact: "inspector.martinez@empresa.com",
      phone: "+1234567892"
    },
    assignedTo: {
      name: "Perito García",
      role: "Perito Evaluador",
      contact: "perito.garcia@empresa.com",
      phone: "+1234567893"
    },
    location: "Terminal Norte - Estacionamiento A",
    createdAt: "2024-01-20T15:45:00",
    evaluationDate: "2024-01-22T09:00:00",
    estimatedCost: 15000.00,
    damageTypes: ["frontal", "motor", "parabrisas", "sistema_direccion"],
    hasInsurance: true,
    insuranceCase: "INS-2024-001",
    insuranceCompany: "Seguros Unidos S.A.",
    attachments: [
      { name: "reporte_accidente.pdf", type: "pdf", size: "3.2 MB", url: "#" },
      { name: "foto_frontal_1.jpg", type: "image", size: "2.8 MB", url: "https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=400" },
      { name: "foto_frontal_2.jpg", type: "image", size: "2.6 MB", url: "https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=400" },
      { name: "foto_motor.jpg", type: "image", size: "3.1 MB", url: "https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400" }
    ],
    timeline: [
      { date: "2024-01-20T15:45:00", event: "Reporte de accidente", user: "Inspector Martínez", type: "created" },
      { date: "2024-01-20T16:30:00", event: "Evidencia fotográfica capturada", user: "Inspector Martínez", type: "documentation" },
      { date: "2024-01-21T09:00:00", event: "Asignado a perito", user: "Sistema", type: "assigned" },
      { date: "2024-01-21T14:30:00", event: "Contacto con aseguradora", user: "Coordinador Ramos", type: "insurance" }
    ],
    comments: [
      {
        id: 1,
        user: "Inspector Martínez",
        role: "Inspector",
        date: "2024-01-20T16:00:00",
        message: "Daños significativos en parte frontal. El conductor está bien. Vehículo remolcado a terminal norte.",
        type: "report"
      },
      {
        id: 2,
        user: "Coordinador Ramos",
        role: "Coordinador",
        date: "2024-01-21T14:30:00",
        message: "Seguro contactado. Número de caso: INS-2024-001. Perito será enviado mañana a las 9:00 AM.",
        type: "update"
      }
    ]
  },
  // Tickets adicionales para pruebas
  "MNT-002": {
    id: "MNT-002",
    type: "maintenance",
    title: "Reparación sistema de frenos",
    status: "pending" as const,
    priority: "high",
    description: "Reparación urgente del sistema de frenos debido a desgaste excesivo de pastillas detectado en inspección rutinaria.",
    truck: {
      id: "TRK-002",
      plate: "DEF-456",
      model: "Mercedes Actros 1845",
      year: 2019,
      mileage: 182000,
      image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
    },
    reportedBy: {
      name: "Conductor López",
      role: "Conductor",
      contact: "conductor.lopez@empresa.com",
      phone: "+1234567894"
    },
    assignedTo: {
      name: "Luis Rodríguez",
      role: "Técnico Especialista",
      contact: "luis.rodriguez@empresa.com",
      phone: "+1234567895"
    },
    location: "Bay 2 - Taller Principal",
    createdAt: "2024-01-19T14:30:00",
    scheduledDate: "2024-01-21T07:00:00",
    dueDate: "2024-01-21T18:00:00",
    estimatedCost: 3500.00,
    actualCost: 0.00,
    estimatedHours: 8,
    actualHours: 0,
    progress: 0,
    parts: [
      { name: "Pastillas freno delanteras", quantity: 1, cost: 280.00, status: "pending" },
      { name: "Discos freno delanteros", quantity: 2, cost: 450.00, status: "pending" },
      { name: "Líquido frenos DOT 4", quantity: 2, cost: 45.00, status: "pending" }
    ],
    attachments: [
      { name: "inspeccion_frenos.pdf", type: "pdf", size: "1.9 MB", url: "#" }
    ],
    timeline: [
      { date: "2024-01-19T14:30:00", event: "Reporte de problema", user: "Conductor López", type: "created" },
      { date: "2024-01-20T09:00:00", event: "Inspección inicial", user: "Supervisor Técnico", type: "inspection" },
      { date: "2024-01-20T15:00:00", event: "Asignado a técnico", user: "Sistema", type: "assigned" }
    ],
    comments: [
      {
        id: 1,
        user: "Conductor López",
        role: "Conductor",
        date: "2024-01-19T14:30:00",
        message: "El pedal de freno se siente esponjoso y hay ruidos al frenar. Requiere atención urgente.",
        type: "report"
      }
    ]
  },
  "EVL-002": {
    id: "EVL-002",
    type: "evaluation",
    title: "Evaluación de desgaste de carrocería",
    status: "in-progress" as const,
    priority: "medium",
    severity: "medium",
    description: "Evaluación programada para inspeccionar desgaste general de carrocería y sistema de pintura como parte del mantenimiento preventivo.",
    truck: {
      id: "TRK-002",
      plate: "DEF-456",
      model: "Mercedes Actros 1845",
      year: 2019,
      mileage: 182000,
      image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
    },
    reportedBy: {
      name: "Supervisor López",
      role: "Supervisor de Mantenimiento",
      contact: "supervisor.lopez@empresa.com",
      phone: "+1234567896"
    },
    assignedTo: {
      name: "Técnico Ruiz",
      role: "Inspector de Carrocería",
      contact: "tecnico.ruiz@empresa.com",
      phone: "+1234567897"
    },
    location: "Taller Principal - Área Inspección",
    createdAt: "2024-01-19T10:00:00",
    evaluationDate: "2024-01-21T09:00:00",
    estimatedCost: 5500.00,
    damageTypes: ["pintura", "oxidacion", "desgaste_general"],
    hasInsurance: false,
    attachments: [
      { name: "checklist_carroceria.pdf", type: "pdf", size: "2.1 MB", url: "#" },
      { name: "foto_lateral_izq.jpg", type: "image", size: "2.3 MB", url: "https://images.unsplash.com/photo-1586473219010-2ffc57b0d282?w=400" }
    ],
    timeline: [
      { date: "2024-01-19T10:00:00", event: "Evaluación programada", user: "Supervisor López", type: "created" },
      { date: "2024-01-20T14:00:00", event: "Asignado a inspector", user: "Sistema", type: "assigned" },
      { date: "2024-01-21T09:00:00", event: "Inspección iniciada", user: "Técnico Ruiz", type: "started" }
    ],
    comments: [
      {
        id: 1,
        user: "Técnico Ruiz",
        role: "Inspector",
        date: "2024-01-21T09:30:00",
        message: "Iniciando inspección visual. Se observa desgaste normal de pintura en zona de carga.",
        type: "update"
      }
    ]
  },
  "TCK-001": {
    id: "TCK-001",
    type: "maintenance",
    title: "Cambio de aceite",
    status: "pending" as const,
    priority: "medium",
    description: "Mantenimiento rutinario de cambio de aceite motor según cronograma establecido.",
    truck: {
      id: "TRK-001",
      plate: "ABC-123",
      model: "Volvo FH 460",
      year: 2020,
      mileage: 145000,
      image: "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
    },
    reportedBy: {
      name: "Juan Pérez",
      role: "Coordinador de Flota",
      contact: "juan.perez@empresa.com",
      phone: "+1234567898"
    },
    assignedTo: {
      name: "Carlos García",
      role: "Técnico Mecánico",
      contact: "carlos.garcia@empresa.com",
      phone: "+1234567899"
    },
    location: "Terminal Norte",
    createdAt: "2024-01-20T08:00:00",
    scheduledDate: "2024-01-25T10:00:00",
    estimatedCost: 1250.00,
    actualCost: 0.00,
    estimatedHours: 4,
    actualHours: 0,
    progress: 0,
    parts: [
      { name: "Aceite 15W40", quantity: 1, cost: 120.00, status: "pending" }
    ],
    attachments: [],
    timeline: [
      { date: "2024-01-20T08:00:00", event: "Ticket creado", user: "Juan Pérez", type: "created" }
    ],
    comments: []
  }
};

interface TicketDetailProps {
  ticketId: string;
  onBack: () => void;
  onNavigate?: (section: string, id?: string) => void;
}

export function TicketDetail({ ticketId, onBack, onNavigate }: TicketDetailProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [newComment, setNewComment] = useState("");
  const [newStatus, setNewStatus] = useState("");
  const [currentTicket, setCurrentTicket] = useState<any>(null);
  const [isUpdatingProgress, setIsUpdatingProgress] = useState(false);

  const ticket = currentTicket || ticketData[ticketId as keyof typeof ticketData];

  // Initialize current ticket state
  useEffect(() => {
    if (ticketData[ticketId as keyof typeof ticketData]) {
      setCurrentTicket(ticketData[ticketId as keyof typeof ticketData]);
    }
  }, [ticketId]);

  if (!ticket) {
    return (
      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <Button variant="ghost" onClick={onBack}>
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <CardTitle>Ticket no encontrado</CardTitle>
              <CardDescription>El ticket solicitado no existe</CardDescription>
            </div>
          </div>
        </CardHeader>
      </Card>
    );
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "critical": return "bg-destructive text-destructive-foreground";
      case "high": return "bg-warning text-warning-foreground";
      case "medium": return "bg-primary text-primary-foreground";
      case "low": return "bg-success text-success-foreground";
      default: return "bg-secondary text-secondary-foreground";
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case "maintenance": return Wrench;
      case "evaluation": return Shield;
      default: return FileText;
    }
  };

  const TypeIcon = getTypeIcon(ticket.type);

  const handleAddComment = () => {
    if (newComment.trim()) {
      // Aquí se agregaría el comentario al sistema
      setNewComment("");
    }
  };

  const handleStatusChange = () => {
    if (newStatus) {
      // Aquí se actualizaría el estado en el sistema
      setCurrentTicket((prev: any) => ({
        ...prev,
        status: newStatus
      }));
      toast.success("Estado actualizado", {
        description: `El ticket ${ticket.id} ahora está ${newStatus === "pending" ? "pendiente" : 
                     newStatus === "in-progress" ? "en progreso" : 
                     newStatus === "completed" ? "completado" : "cancelado"}.`
      });
      setNewStatus("");
    }
  };

  const handleProgressUpdate = async (newProgress: number[]) => {
    if (ticket.type === "maintenance") {
      setIsUpdatingProgress(true);
      try {
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 500));
        
        setCurrentTicket((prev: any) => ({
          ...prev,
          progress: newProgress[0]
        }));
        
        toast.success("Progreso actualizado", {
          description: `Progreso actualizado a ${newProgress[0]}%`
        });
      } catch (error) {
        toast.error("Error al actualizar progreso");
      } finally {
        setIsUpdatingProgress(false);
      }
    }
  };

  const handleTicketSave = (updatedTicket: any) => {
    setCurrentTicket(updatedTicket);
    // Here you would also update the global state or send to API
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card className="glass-effect shadow-gold">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div className="flex items-start gap-4">
              <Button variant="ghost" onClick={onBack} className="hover-lift">
                <ArrowLeft className="h-4 w-4" />
              </Button>
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <TypeIcon className="h-6 w-6 text-primary" />
                  <h1 className="text-2xl font-bold bg-gradient-primary bg-clip-text text-transparent">
                    {ticket.id}
                  </h1>
                  <StatusBadge status={ticket.status} />
                  <Badge className={getPriorityColor(ticket.priority)}>
                    {ticket.priority === "high" ? "Alta" : 
                     ticket.priority === "medium" ? "Media" : 
                     ticket.priority === "low" ? "Baja" : "Crítica"}
                  </Badge>
                  {ticket.type === "evaluation" && ticket.severity && (
                    <Badge variant="outline" className="border-warning text-warning">
                      Severidad: {ticket.severity === "high" ? "Alta" : 
                                  ticket.severity === "medium" ? "Media" : "Baja"}
                    </Badge>
                  )}
                </div>
                <h2 className="text-xl mb-2">{ticket.title}</h2>
                <p className="text-muted-foreground">{ticket.description}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Button 
                variant="outline" 
                onClick={() => setIsEditModalOpen(true)} 
                className="hover-lift"
              >
                <Edit className="h-4 w-4 mr-2" />
                Editar
              </Button>
              <Button className="gradient-primary hover-lift">
                <CheckCircle className="h-4 w-4 mr-2" />
                Completar
              </Button>
            </div>
          </div>
        </CardHeader>
      </Card>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="xl:col-span-2 space-y-6">
          
          {/* Truck Information */}
          <Card className="hover-lift">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Truck className="h-5 w-5 text-primary" />
                Información del Vehículo
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-start gap-4">
                <ImageWithFallback
                  src={ticket.truck.image}
                  alt={ticket.truck.model}
                  className="h-20 w-20 rounded-xl object-cover border-2 border-muted shadow-md"
                />
                <div className="flex-1 grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Placa</p>
                    <p className="font-semibold">{ticket.truck.plate}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Modelo</p>
                    <p className="font-semibold">{ticket.truck.model}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Año</p>
                    <p className="font-semibold">{ticket.truck.year}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Kilometraje</p>
                    <p className="font-semibold">{ticket.truck.mileage.toLocaleString()} km</p>
                  </div>
                </div>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={() => onNavigate?.("trucks", ticket.truck.id)}
                  className="hover-lift"
                >
                  Ver Perfil
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Progress & Details (for maintenance) */}
          {ticket.type === "maintenance" && (
            <Card className="hover-lift">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Activity className="h-5 w-5 text-primary" />
                  Progreso y Detalles
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="text-center p-4 border rounded-lg">
                    <Timer className="h-6 w-6 text-primary mx-auto mb-2" />
                    <p className="text-2xl font-bold">{ticket.actualHours}h</p>
                    <p className="text-sm text-muted-foreground">de {ticket.estimatedHours}h</p>
                  </div>
                  <div className="text-center p-4 border rounded-lg">
                    <DollarSign className="h-6 w-6 text-success mx-auto mb-2" />
                    <p className="text-2xl font-bold">${ticket.actualCost}</p>
                    <p className="text-sm text-muted-foreground">de ${ticket.estimatedCost}</p>
                  </div>
                  <div className="text-center p-4 border rounded-lg">
                    <TrendingUp className="h-6 w-6 text-info mx-auto mb-2" />
                    <p className="text-2xl font-bold">{ticket.progress}%</p>
                    <p className="text-sm text-muted-foreground">Completado</p>
                  </div>
                  <div className="text-center p-4 border rounded-lg">
                    <Settings className="h-6 w-6 text-warning mx-auto mb-2" />
                    <p className="text-2xl font-bold">{ticket.parts.length}</p>
                    <p className="text-sm text-muted-foreground">Componentes</p>
                  </div>
                </div>

                {/* Interactive Progress Bar */}
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h4 className="font-semibold">Control de Progreso</h4>
                    <Badge variant="outline" className={isUpdatingProgress ? "animate-pulse" : ""}>
                      {isUpdatingProgress ? "Actualizando..." : `${ticket.progress}% completado`}
                    </Badge>
                  </div>
                  
                  <div className="space-y-3">
                    <Progress value={ticket.progress} className="h-3" />
                    <div className="space-y-2">
                      <div className="flex items-center justify-between text-sm text-muted-foreground">
                        <span>0%</span>
                        <span>Ajustar progreso</span>
                        <span>100%</span>
                      </div>
                      <Slider
                        value={[ticket.progress]}
                        onValueChange={handleProgressUpdate}
                        disabled={isUpdatingProgress}
                        max={100}
                        step={5}
                        className="w-full"
                      />
                    </div>
                  </div>
                  
                  <div className="flex gap-2">
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleProgressUpdate([0])}
                      disabled={isUpdatingProgress || ticket.progress === 0}
                    >
                      Reiniciar
                    </Button>
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleProgressUpdate([25])}
                      disabled={isUpdatingProgress}
                    >
                      25%
                    </Button>
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleProgressUpdate([50])}
                      disabled={isUpdatingProgress}
                    >
                      50%
                    </Button>
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleProgressUpdate([75])}
                      disabled={isUpdatingProgress}
                    >
                      75%
                    </Button>
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleProgressUpdate([100])}
                      disabled={isUpdatingProgress || ticket.progress === 100}
                      className="text-success border-success hover:bg-success hover:text-success-foreground"
                    >
                      Completar
                    </Button>
                  </div>
                </div>

                {/* Parts List */}
                <div>
                  <h4 className="font-semibold mb-3">Repuestos y Componentes</h4>
                  <div className="space-y-2">
                    {ticket.parts.map((part, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                        <div className="flex-1">
                          <p className="font-medium">{part.name}</p>
                          <p className="text-sm text-muted-foreground">Cantidad: {part.quantity}</p>
                        </div>
                        <div className="text-right">
                          <p className="font-semibold">${part.cost.toFixed(2)}</p>
                          <Badge variant={part.status === "used" ? "default" : "secondary"} className="text-xs">
                            {part.status === "used" ? "Usado" : "Pendiente"}
                          </Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Damage Information (for evaluation) */}
          {ticket.type === "evaluation" && (
            <Card className="hover-lift">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5 text-warning" />
                  Información de Daños
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Costo Estimado</p>
                    <p className="text-2xl font-bold text-warning">${ticket.estimatedCost.toLocaleString()}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Tipos de Daño</p>
                    <div className="flex flex-wrap gap-1 mt-1">
                      {ticket.damageTypes?.map((damage, index) => (
                        <Badge key={index} variant="outline" className="text-xs">
                          {damage.replace("_", " ")}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </div>

                {ticket.hasInsurance && (
                  <div className="p-4 border-l-4 border-success bg-success/5 rounded-r-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Shield className="h-4 w-4 text-success" />
                      <p className="font-semibold text-success">Cobertura de Seguro</p>
                    </div>
                    <p className="text-sm">Caso: <span className="font-mono">{ticket.insuranceCase}</span></p>
                    <p className="text-sm">Aseguradora: {ticket.insuranceCompany}</p>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Attachments */}
          <Card className="hover-lift">
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="flex items-center gap-2">
                  <ImageIcon className="h-5 w-5 text-primary" />
                  Archivos Adjuntos ({ticket.attachments.length})
                </CardTitle>
                <Button variant="outline" size="sm" className="hover-lift">
                  <Upload className="h-4 w-4 mr-2" />
                  Subir Archivo
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {ticket.attachments.map((file, index) => (
                  <div key={index} className="flex items-center gap-3 p-3 border rounded-lg hover:bg-muted/50 transition-colors">
                    {file.type === "image" ? (
                      <div className="relative">
                        <ImageWithFallback
                          src={file.url}
                          alt={file.name}
                          className="h-12 w-12 rounded-lg object-cover"
                        />
                        <Camera className="absolute -top-1 -right-1 h-4 w-4 text-primary bg-background rounded-full p-0.5" />
                      </div>
                    ) : (
                      <div className="h-12 w-12 rounded-lg bg-muted flex items-center justify-center">
                        <FileText className="h-6 w-6 text-muted-foreground" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="font-medium truncate">{file.name}</p>
                      <p className="text-sm text-muted-foreground">{file.size}</p>
                    </div>
                    <Button variant="ghost" size="sm">
                      <Download className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Comments */}
          <Card className="hover-lift">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MessageSquare className="h-5 w-5 text-primary" />
                Comentarios y Actualizaciones
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Add comment */}
              <div className="space-y-3">
                <Textarea
                  placeholder="Agregar comentario o actualización..."
                  value={newComment}
                  onChange={(e) => setNewComment(e.target.value)}
                  className="min-h-[80px]"
                />
                <div className="flex justify-end">
                  <Button onClick={handleAddComment} disabled={!newComment.trim()} className="gradient-primary">
                    <MessageSquare className="h-4 w-4 mr-2" />
                    Agregar Comentario
                  </Button>
                </div>
              </div>

              <Separator />

              {/* Comments list */}
              <div className="space-y-4">
                {ticket.comments.map((comment) => (
                  <div key={comment.id} className="flex gap-3 p-4 border rounded-lg">
                    <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                      <User className="h-4 w-4 text-primary" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="font-semibold text-sm">{comment.user}</p>
                        <Badge variant="outline" className="text-xs">{comment.role}</Badge>
                        <p className="text-xs text-muted-foreground">
                          {new Date(comment.date).toLocaleString('es-ES')}
                        </p>
                      </div>
                      <p className="text-sm">{comment.message}</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          
          {/* Quick Actions */}
          <Card className="glass-effect">
            <CardHeader>
              <CardTitle className="text-lg">Acciones Rápidas</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-2">
                <label className="text-sm font-medium">Cambiar Estado</label>
                <Select value={newStatus} onValueChange={setNewStatus}>
                  <SelectTrigger>
                    <SelectValue placeholder="Seleccionar estado..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="pending">Pendiente</SelectItem>
                    <SelectItem value="in-progress">En Progreso</SelectItem>
                    <SelectItem value="completed">Completado</SelectItem>
                    <SelectItem value="cancelled">Cancelado</SelectItem>
                  </SelectContent>
                </Select>
                <Button 
                  onClick={handleStatusChange} 
                  disabled={!newStatus}
                  className="w-full gradient-primary"
                >
                  Actualizar Estado
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Key Information */}
          <Card className="hover-lift">
            <CardHeader>
              <CardTitle className="text-lg">Información Clave</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-muted-foreground flex items-center gap-2">
                    <User className="h-4 w-4" />
                    Reportado por
                  </p>
                  <p className="font-semibold">{ticket.reportedBy.name}</p>
                  <p className="text-sm text-muted-foreground">{ticket.reportedBy.role}</p>
                  <div className="flex gap-2 mt-1">
                    <Button variant="ghost" size="sm">
                      <Mail className="h-3 w-3" />
                    </Button>
                    <Button variant="ghost" size="sm">
                      <Phone className="h-3 w-3" />
                    </Button>
                  </div>
                </div>

                <Separator />

                <div>
                  <p className="text-sm text-muted-foreground flex items-center gap-2">
                    <User className="h-4 w-4" />
                    Asignado a
                  </p>
                  <p className="font-semibold">{ticket.assignedTo.name}</p>
                  <p className="text-sm text-muted-foreground">{ticket.assignedTo.role}</p>
                  <div className="flex gap-2 mt-1">
                    <Button variant="ghost" size="sm">
                      <Mail className="h-3 w-3" />
                    </Button>
                    <Button variant="ghost" size="sm">
                      <Phone className="h-3 w-3" />
                    </Button>
                  </div>
                </div>

                <Separator />

                <div>
                  <p className="text-sm text-muted-foreground flex items-center gap-2">
                    <MapPin className="h-4 w-4" />
                    Ubicación
                  </p>
                  <p className="font-semibold">{ticket.location}</p>
                </div>

                <Separator />

                <div>
                  <p className="text-sm text-muted-foreground flex items-center gap-2">
                    <Calendar className="h-4 w-4" />
                    Fechas Importantes
                  </p>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span>Creado:</span>
                      <span>{new Date(ticket.createdAt).toLocaleDateString('es-ES')}</span>
                    </div>
                    {ticket.scheduledDate && (
                      <div className="flex justify-between">
                        <span>Programado:</span>
                        <span>{new Date(ticket.scheduledDate).toLocaleDateString('es-ES')}</span>
                      </div>
                    )}
                    {ticket.evaluationDate && (
                      <div className="flex justify-between">
                        <span>Evaluación:</span>
                        <span>{new Date(ticket.evaluationDate).toLocaleDateString('es-ES')}</span>
                      </div>
                    )}
                    {ticket.dueDate && (
                      <div className="flex justify-between">
                        <span>Vencimiento:</span>
                        <span>{new Date(ticket.dueDate).toLocaleDateString('es-ES')}</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Timeline */}
          <Card className="hover-lift">
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <Clock className="h-5 w-5 text-primary" />
                Cronología
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {ticket.timeline.map((event, index) => (
                  <div key={index} className="flex gap-3">
                    <div className="h-2 w-2 rounded-full bg-primary mt-2 flex-shrink-0" />
                    <div className="flex-1 pb-4">
                      <p className="text-sm font-medium">{event.event}</p>
                      <p className="text-xs text-muted-foreground">{event.user}</p>
                      <p className="text-xs text-muted-foreground">
                        {new Date(event.date).toLocaleString('es-ES')}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Edit Modal */}
      <EditTicketModal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        ticket={ticket}
        onSave={handleTicketSave}
      />
    </div>
  );
}