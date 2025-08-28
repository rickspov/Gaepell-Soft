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
  Filter,
  Plus,
  Eye,
  Edit,
  Trash2,
  Download,
  Calendar,
  User,
  Truck
} from "lucide-react";

// Mock data
const ticketsData = [
  {
    id: "TCK-001",
    title: "Cambio de aceite",
    truck: { id: "TRK-001", plate: "ABC-123", model: "Volvo FH 460" },
    type: "preventive",
    status: "pending" as const,
    priority: "medium",
    reportedBy: "Juan Pérez",
    assignedTo: "Carlos García",
    createdAt: "2024-01-20",
    dueDate: "2024-01-25",
    estimatedCost: 1250.00,
    location: "Terminal Norte"
  },
  {
    id: "TCK-002",
    title: "Reparación frenos",
    truck: { id: "TRK-002", plate: "DEF-456", model: "Mercedes Actros 1845" },
    type: "mechanical",
    status: "in-progress" as const,
    priority: "high",
    reportedBy: "María López",
    assignedTo: "Luis Rodríguez",
    createdAt: "2024-01-19",
    dueDate: "2024-01-22",
    estimatedCost: 3500.00,
    location: "Taller Principal"
  },
  {
    id: "TCK-003",
    title: "Revisión general",
    truck: { id: "TRK-003", plate: "GHI-789", model: "Scania R 450" },
    type: "inspection",
    status: "completed" as const,
    priority: "low",
    reportedBy: "Carlos Ruiz",
    assignedTo: "Ana Martínez",
    createdAt: "2024-01-18",
    dueDate: "2024-01-21",
    estimatedCost: 800.00,
    location: "Terminal Sur"
  },
  {
    id: "TCK-004",
    title: "Reemplazo de neumáticos",
    truck: { id: "TRK-001", plate: "ABC-123", model: "Volvo FH 460" },
    type: "mechanical",
    status: "pending" as const,
    priority: "medium",
    reportedBy: "Pedro Gómez",
    assignedTo: "Carlos García",
    createdAt: "2024-01-17",
    dueDate: "2024-01-24",
    estimatedCost: 2100.00,
    location: "Terminal Norte"
  },
  {
    id: "TCK-005",
    title: "Problema eléctrico",
    truck: { id: "TRK-002", plate: "DEF-456", model: "Mercedes Actros 1845" },
    type: "electrical",
    status: "cancelled" as const,
    priority: "high",
    reportedBy: "Laura Silva",
    assignedTo: "María López",
    createdAt: "2024-01-16",
    dueDate: "2024-01-20",
    estimatedCost: 1800.00,
    location: "Taller Eléctrico"
  }
];

const typeLabels = {
  mechanical: "Mecánico",
  electrical: "Eléctrico",
  bodywork: "Carrocería",
  preventive: "Preventivo",
  inspection: "Inspección"
};

const priorityLabels = {
  low: "Baja",
  medium: "Media",
  high: "Alta"
};

interface TicketsListProps {
  onNavigate?: (section: string, id?: string) => void;
}

export function TicketsList({ onNavigate }: TicketsListProps) {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [priorityFilter, setPriorityFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");

  const filteredTickets = ticketsData.filter(ticket => {
    const matchesSearch = 
      ticket.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.truck.plate.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.reportedBy.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === "all" || ticket.status === statusFilter;
    const matchesPriority = priorityFilter === "all" || ticket.priority === priorityFilter;
    const matchesType = typeFilter === "all" || ticket.type === typeFilter;

    return matchesSearch && matchesStatus && matchesPriority && matchesType;
  });

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "high": return "bg-destructive text-destructive-foreground";
      case "medium": return "bg-warning text-warning-foreground";
      case "low": return "bg-success text-success-foreground";
      default: return "bg-secondary text-secondary-foreground";
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Tickets de Mantenimiento</h1>
          <p className="text-muted-foreground">Gestiona los reportes y solicitudes de mantenimiento</p>
        </div>
        <Button onClick={() => onNavigate?.("tickets", "new")}>
          <Plus className="h-4 w-4 mr-2" />
          Nuevo Ticket
        </Button>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Filtros y Búsqueda</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            <div className="md:col-span-2">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar por ID, título, camión o reportante..."
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
                <SelectItem value="pending">Pendiente</SelectItem>
                <SelectItem value="in-progress">En Progreso</SelectItem>
                <SelectItem value="completed">Completado</SelectItem>
                <SelectItem value="cancelled">Cancelado</SelectItem>
              </SelectContent>
            </Select>

            <Select value={priorityFilter} onValueChange={setPriorityFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Prioridad" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todas las prioridades</SelectItem>
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
                <SelectItem value="mechanical">Mecánico</SelectItem>
                <SelectItem value="electrical">Eléctrico</SelectItem>
                <SelectItem value="bodywork">Carrocería</SelectItem>
                <SelectItem value="preventive">Preventivo</SelectItem>
                <SelectItem value="inspection">Inspección</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="text-center">
              <p className="text-2xl font-bold text-warning">{ticketsData.filter(t => t.status === 'pending').length}</p>
              <p className="text-sm text-muted-foreground">Pendientes</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-center">
              <p className="text-2xl font-bold text-primary">{ticketsData.filter(t => t.status === 'in-progress').length}</p>
              <p className="text-sm text-muted-foreground">En Progreso</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-center">
              <p className="text-2xl font-bold text-success">{ticketsData.filter(t => t.status === 'completed').length}</p>
              <p className="text-sm text-muted-foreground">Completados</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-center">
              <p className="text-2xl font-bold">{filteredTickets.length}</p>
              <p className="text-sm text-muted-foreground">Total Filtrados</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tickets Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Lista de Tickets</CardTitle>
              <CardDescription>
                Mostrando {filteredTickets.length} de {ticketsData.length} tickets
              </CardDescription>
            </div>
            <Button variant="outline">
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
                  <TableHead>Prioridad</TableHead>
                  <TableHead>Asignado a</TableHead>
                  <TableHead>Fecha Límite</TableHead>
                  <TableHead>Costo Est.</TableHead>
                  <TableHead>Acciones</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredTickets.map((ticket) => (
                  <TableRow key={ticket.id}>
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
                        {typeLabels[ticket.type as keyof typeof typeLabels]}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={ticket.status} />
                    </TableCell>
                    <TableCell>
                      <Badge className={getPriorityColor(ticket.priority)}>
                        {priorityLabels[ticket.priority as keyof typeof priorityLabels]}
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
                          {new Date(ticket.dueDate).toLocaleDateString('es-ES')}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="font-medium">
                        ${ticket.estimatedCost.toLocaleString('es-ES')}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Button variant="ghost" size="sm" onClick={() => onNavigate?.("tickets", ticket.id)}>
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm">
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm">
                          <Trash2 className="h-4 w-4" />
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
              <p className="text-muted-foreground">No se encontraron tickets que coincidan con los filtros.</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}