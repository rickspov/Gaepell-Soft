import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Badge } from "./ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";
import { StatusBadge } from "./status-badge";
import { 
  Search,
  Plus,
  Eye,
  Edit,
  Download,
  Calendar,
  User,
  Truck,
  FileText,
  AlertTriangle,
  Clock,
  DollarSign,
  Camera,
  Shield
} from "lucide-react";

// Mock data para tickets de evaluación
const evaluationTicketsData = [
  {
    id: "EVL-001",
    title: "Evaluación de daños por colisión frontal",
    truck: { id: "TRK-001", plate: "ABC-123", model: "Volvo FH 460" },
    evaluationType: "accident",
    status: "pending" as const,
    severity: "high",
    reportedBy: "Inspector Martínez",
    assignedTo: "Perito García",
    createdAt: "2024-01-20",
    evaluationDate: "2024-01-22",
    estimatedCost: 15000.00,
    location: "Terminal Norte",
    damageTypes: ["frontal", "motor", "parabrisas"],
    photos: 8,
    hasInsurance: true,
    insuranceCase: "INS-2024-001"
  },
  {
    id: "EVL-002", 
    title: "Evaluación de desgaste de carrocería",
    truck: { id: "TRK-002", plate: "DEF-456", model: "Mercedes Actros 1845" },
    evaluationType: "wear",
    status: "in-progress" as const,
    severity: "medium",
    reportedBy: "Supervisor López",
    assignedTo: "Técnico Ruiz",
    createdAt: "2024-01-19",
    evaluationDate: "2024-01-21",
    estimatedCost: 5500.00,
    location: "Taller Principal",
    damageTypes: ["pintura", "oxidación"],
    photos: 12,
    hasInsurance: false,
    insuranceCase: null
  },
  {
    id: "EVL-003",
    title: "Evaluación post-mantenimiento mayor",
    truck: { id: "TRK-003", plate: "GHI-789", model: "Scania R 450" },
    evaluationType: "post-maintenance",
    status: "completed" as const,
    severity: "low",
    reportedBy: "Jefe Taller Silva",
    assignedTo: "Inspector Morales",
    createdAt: "2024-01-18",
    evaluationDate: "2024-01-20",
    estimatedCost: 0.00,
    location: "Terminal Sur",
    damageTypes: [],
    photos: 5,
    hasInsurance: false,
    insuranceCase: null
  },
  {
    id: "EVL-004",
    title: "Evaluación de daños por vandalismo",
    truck: { id: "TRK-004", plate: "JKL-012", model: "Volvo FH 500" },
    evaluationType: "vandalism",
    status: "pending" as const,
    severity: "high",
    reportedBy: "Guardia Torres",
    assignedTo: "Perito Vega",
    createdAt: "2024-01-17",
    evaluationDate: "2024-01-23",
    estimatedCost: 8750.00,
    location: "Estacionamiento Central",
    damageTypes: ["cristales", "pintura", "espejos"],
    photos: 15,
    hasInsurance: true,
    insuranceCase: "INS-2024-002"
  },
  {
    id: "EVL-005",
    title: "Evaluación rutinaria de flota",
    truck: { id: "TRK-005", plate: "MNO-345", model: "Mercedes Actros 1836" },
    evaluationType: "routine",
    status: "scheduled" as const,
    severity: "low",
    reportedBy: "Coordinador Ramos",
    assignedTo: "Inspector González",
    createdAt: "2024-01-16",
    evaluationDate: "2024-01-25",
    estimatedCost: 0.00,
    location: "Terminal Este",
    damageTypes: [],
    photos: 0,
    hasInsurance: false,
    insuranceCase: null
  }
];

const evaluationTypeLabels = {
  accident: "Accidente",
  wear: "Desgaste",
  vandalism: "Vandalismo", 
  routine: "Rutinaria",
  "post-maintenance": "Post-Mantenimiento"
};

const severityLabels = {
  low: "Baja",
  medium: "Media", 
  high: "Alta",
  critical: "Crítica"
};

interface EvaluationTicketsProps {
  onNavigate?: (section: string, id?: string) => void;
}

export function EvaluationTickets({ onNavigate }: EvaluationTicketsProps) {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [severityFilter, setSeverityFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");
  const [insuranceFilter, setInsuranceFilter] = useState("all");

  const filteredTickets = evaluationTicketsData.filter(ticket => {
    const matchesSearch = 
      ticket.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.truck.plate.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.reportedBy.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === "all" || ticket.status === statusFilter;
    const matchesSeverity = severityFilter === "all" || ticket.severity === severityFilter;
    const matchesType = typeFilter === "all" || ticket.evaluationType === typeFilter;
    const matchesInsurance = insuranceFilter === "all" || 
      (insuranceFilter === "with" && ticket.hasInsurance) ||
      (insuranceFilter === "without" && !ticket.hasInsurance);

    return matchesSearch && matchesStatus && matchesSeverity && matchesType && matchesInsurance;
  });

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case "critical": return "bg-destructive text-destructive-foreground";
      case "high": return "bg-warning text-warning-foreground";
      case "medium": return "bg-primary text-primary-foreground";
      case "low": return "bg-success text-success-foreground";
      default: return "bg-secondary text-secondary-foreground";
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold bg-gradient-primary bg-clip-text text-transparent">
            Tickets de Evaluación
          </h1>
          <p className="text-muted-foreground">Gestión de evaluaciones de daños y reportes de inspección</p>
        </div>
        <Button onClick={() => onNavigate?.("evaluations", "new")} className="gradient-primary hover-lift">
          <Plus className="h-4 w-4 mr-2" />
          Nueva Evaluación
        </Button>
      </div>

      {/* Filters */}
      <Card className="glass-effect shadow-gold">
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Search className="h-4 w-4" />
            Filtros y Búsqueda
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-6 gap-4">
            <div className="md:col-span-2">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar por ID, título, camión o inspector..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Estado" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos los estados</SelectItem>
                <SelectItem value="scheduled">Programada</SelectItem>
                <SelectItem value="pending">Pendiente</SelectItem>
                <SelectItem value="in-progress">En Progreso</SelectItem>
                <SelectItem value="completed">Completada</SelectItem>
                <SelectItem value="cancelled">Cancelada</SelectItem>
              </SelectContent>
            </Select>

            <Select value={severityFilter} onValueChange={setSeverityFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Severidad" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todas las severidades</SelectItem>
                <SelectItem value="critical">Crítica</SelectItem>
                <SelectItem value="high">Alta</SelectItem>
                <SelectItem value="medium">Media</SelectItem>
                <SelectItem value="low">Baja</SelectItem>
              </SelectContent>
            </Select>

            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Tipo" />  
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos los tipos</SelectItem>
                <SelectItem value="accident">Accidente</SelectItem>
                <SelectItem value="wear">Desgaste</SelectItem>
                <SelectItem value="vandalism">Vandalismo</SelectItem>
                <SelectItem value="routine">Rutinaria</SelectItem>
                <SelectItem value="post-maintenance">Post-Mantenimiento</SelectItem>
              </SelectContent>
            </Select>

            <Select value={insuranceFilter} onValueChange={setInsuranceFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Seguro" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos</SelectItem>
                <SelectItem value="with">Con Seguro</SelectItem>
                <SelectItem value="without">Sin Seguro</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <Card className="hover-lift">
          <CardContent className="p-4">
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <Clock className="h-5 w-5 text-warning" />
              </div>
              <p className="text-2xl font-bold text-warning">
                {evaluationTicketsData.filter(t => t.status === 'pending').length}
              </p>
              <p className="text-sm text-muted-foreground">Pendientes</p>
            </div>
          </CardContent>
        </Card>
        
        <Card className="hover-lift">
          <CardContent className="p-4">
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <Eye className="h-5 w-5 text-primary" />
              </div>
              <p className="text-2xl font-bold text-primary">
                {evaluationTicketsData.filter(t => t.status === 'in-progress').length}
              </p>
              <p className="text-sm text-muted-foreground">En Progreso</p>
            </div>
          </CardContent>
        </Card>
        
        <Card className="hover-lift">
          <CardContent className="p-4">
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <Shield className="h-5 w-5 text-success" />
              </div>
              <p className="text-2xl font-bold text-success">
                {evaluationTicketsData.filter(t => t.status === 'completed').length}
              </p>
              <p className="text-sm text-muted-foreground">Completadas</p>
            </div>
          </CardContent>
        </Card>
        
        <Card className="hover-lift">
          <CardContent className="p-4">
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <AlertTriangle className="h-5 w-5 text-destructive" />
              </div>
              <p className="text-2xl font-bold text-destructive">
                {evaluationTicketsData.filter(t => t.severity === 'high' || t.severity === 'critical').length}
              </p>
              <p className="text-sm text-muted-foreground">Alta Prioridad</p>
            </div>
          </CardContent>
        </Card>
        
        <Card className="hover-lift">
          <CardContent className="p-4">
            <div className="text-center">
              <div className="flex items-center justify-center mb-2">
                <FileText className="h-5 w-5 text-primary" />
              </div>
              <p className="text-2xl font-bold">{filteredTickets.length}</p>
              <p className="text-sm text-muted-foreground">Total Filtrados</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Evaluations Table */}
      <Card className="glass-effect">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Lista de Evaluaciones</CardTitle>
              <CardDescription>
                Mostrando {filteredTickets.length} de {evaluationTicketsData.length} evaluaciones
              </CardDescription>
            </div>
            <Button variant="outline" className="hover-lift">
              <Download className="h-4 w-4 mr-2" />
              Exportar
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ID</TableHead>
                  <TableHead>Título</TableHead>
                  <TableHead>Camión</TableHead>
                  <TableHead>Tipo</TableHead>
                  <TableHead>Estado</TableHead>
                  <TableHead>Severidad</TableHead>
                  <TableHead>Asignado a</TableHead>
                  <TableHead>Fecha Evaluación</TableHead>
                  <TableHead>Costo Est.</TableHead>
                  <TableHead>Fotos</TableHead>
                  <TableHead>Seguro</TableHead>
                  <TableHead>Acciones</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredTickets.map((ticket) => (
                  <TableRow key={ticket.id} className="hover:bg-muted/50">
                    <TableCell className="font-medium">{ticket.id}</TableCell>
                    <TableCell>
                      <div>
                        <p className="font-medium">{ticket.title}</p>
                        <p className="text-xs text-muted-foreground">
                          Por: {ticket.reportedBy}
                        </p>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Truck className="h-4 w-4 text-muted-foreground" />
                        <div>
                          <p className="font-medium">{ticket.truck.plate}</p>
                          <p className="text-xs text-muted-foreground">{ticket.truck.model}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">
                        {evaluationTypeLabels[ticket.evaluationType as keyof typeof evaluationTypeLabels]}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={ticket.status} />
                    </TableCell>
                    <TableCell>
                      <Badge className={getSeverityColor(ticket.severity)}>
                        {severityLabels[ticket.severity as keyof typeof severityLabels]}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm">{ticket.assignedTo}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm">
                          {new Date(ticket.evaluationDate).toLocaleDateString('es-ES')}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <DollarSign className="h-4 w-4 text-success" />
                        <span className="font-medium">
                          ${ticket.estimatedCost.toLocaleString('es-ES')}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Camera className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm">{ticket.photos}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      {ticket.hasInsurance ? (
                        <div className="flex items-center gap-1">
                          <Shield className="h-4 w-4 text-success" />
                          <span className="text-xs text-success">{ticket.insuranceCase}</span>
                        </div>
                      ) : (
                        <span className="text-xs text-muted-foreground">Sin seguro</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Button variant="ghost" size="sm" onClick={() => onNavigate?.("evaluations", ticket.id)}>
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm">
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm">
                          <FileText className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>

          {filteredTickets.length === 0 && (
            <div className="text-center py-8">
              <AlertTriangle className="h-8 w-8 text-muted-foreground mx-auto mb-2" />
              <p className="text-muted-foreground">No se encontraron evaluaciones que coincidan con los filtros.</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}