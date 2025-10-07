import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "./ui/dialog";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Textarea } from "./ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Calendar } from "./ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";
import { Badge } from "./ui/badge";
import { Separator } from "./ui/separator";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { ScrollArea } from "./ui/scroll-area";
import { Switch } from "./ui/switch";
import { toast } from "sonner@2.0.3";
import { 
  Calendar as CalendarIcon,
  Clock,
  User,
  MapPin,
  DollarSign,
  AlertTriangle,
  Shield,
  Wrench,
  FileText,
  Save,
  X,
  CheckCircle
} from "lucide-react";
// Helper function to format dates
const formatDate = (date: Date) => {
  return date.toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

interface EditTicketModalProps {
  isOpen: boolean;
  onClose: () => void;
  ticket: any;
  onSave: (updatedTicket: any) => void;
}

// Mock data para usuarios disponibles
const availableUsers = [
  { id: "1", name: "Carlos García", role: "Técnico Mecánico" },
  { id: "2", name: "Luis Rodríguez", role: "Técnico Especialista" },
  { id: "3", name: "Perito García", role: "Perito Evaluador" },
  { id: "4", name: "Técnico Ruiz", role: "Inspector de Carrocería" },
  { id: "5", name: "Ana Martínez", role: "Supervisora Técnica" }
];

const priorityOptions = [
  { value: "low", label: "Baja", color: "bg-success" },
  { value: "medium", label: "Media", color: "bg-primary" },
  { value: "high", label: "Alta", color: "bg-warning" },
  { value: "critical", label: "Crítica", color: "bg-destructive" }
];

const statusOptions = [
  { value: "pending", label: "Pendiente" },
  { value: "scheduled", label: "Programado" },
  { value: "in-progress", label: "En Progreso" },
  { value: "completed", label: "Completado" },
  { value: "cancelled", label: "Cancelado" }
];

const severityOptions = [
  { value: "low", label: "Baja" },
  { value: "medium", label: "Media" },
  { value: "high", label: "Alta" }
];

export function EditTicketModal({ isOpen, onClose, ticket, onSave }: EditTicketModalProps) {
  const [formData, setFormData] = useState<any>({});
  const [scheduledDate, setScheduledDate] = useState<Date | undefined>(undefined);
  const [evaluationDate, setEvaluationDate] = useState<Date | undefined>(undefined);
  const [dueDate, setDueDate] = useState<Date | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (ticket && isOpen) {
      setFormData({
        title: ticket.title || "",
        description: ticket.description || "",
        status: ticket.status || "pending",
        priority: ticket.priority || "medium",
        severity: ticket.severity || "medium",
        location: ticket.location || "",
        estimatedCost: ticket.estimatedCost || 0,
        actualCost: ticket.actualCost || 0,
        estimatedHours: ticket.estimatedHours || 0,
        actualHours: ticket.actualHours || 0,
        assignedTo: ticket.assignedTo?.name || "",
        progress: ticket.progress || 0,
        hasInsurance: ticket.hasInsurance || false,
        insuranceCompany: ticket.insuranceCompany || "",
        insuranceCase: ticket.insuranceCase || ""
      });
      
      // Set dates
      if (ticket.scheduledDate) {
        setScheduledDate(new Date(ticket.scheduledDate));
      }
      if (ticket.evaluationDate) {
        setEvaluationDate(new Date(ticket.evaluationDate));
      }
      if (ticket.dueDate) {
        setDueDate(new Date(ticket.dueDate));
      }
    }
  }, [ticket, isOpen]);

  const handleSave = async () => {
    setIsLoading(true);
    
    try {
      const updatedTicket = {
        ...ticket,
        ...formData,
        scheduledDate: scheduledDate?.toISOString(),
        evaluationDate: evaluationDate?.toISOString(),
        dueDate: dueDate?.toISOString(),
        // Find assigned user details
        assignedTo: {
          ...ticket.assignedTo,
          name: formData.assignedTo
        }
      };

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      onSave(updatedTicket);
      toast.success("Ticket actualizado exitosamente", {
        description: `Los cambios en ${ticket.id} han sido guardados.`
      });
      onClose();
    } catch (error) {
      toast.error("Error al actualizar ticket", {
        description: "Por favor, intenta nuevamente."
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData((prev: any) => ({
      ...prev,
      [field]: value
    }));
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case "maintenance": return Wrench;
      case "evaluation": return Shield;
      default: return FileText;
    }
  };

  const TypeIcon = getTypeIcon(ticket?.type || "");

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-hidden">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <TypeIcon className="h-6 w-6 text-primary" />
            Editar Ticket - {ticket?.id}
            <Badge variant="outline" className="ml-2">
              {ticket?.type === "maintenance" ? "Mantenimiento" : "Evaluación"}
            </Badge>
          </DialogTitle>
          <DialogDescription>
            Modifica los detalles del ticket. Los cambios se guardarán inmediatamente.
          </DialogDescription>
        </DialogHeader>

        <ScrollArea className="max-h-[calc(90vh-200px)] overflow-auto">
          <div className="space-y-6 pr-6">
            
            {/* Basic Information */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Información Básica</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="title">Título</Label>
                    <Input
                      id="title"
                      value={formData.title || ""}
                      onChange={(e) => handleInputChange("title", e.target.value)}
                      placeholder="Título del ticket"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="location">Ubicación</Label>
                    <Input
                      id="location"
                      value={formData.location || ""}
                      onChange={(e) => handleInputChange("location", e.target.value)}
                      placeholder="Ubicación del trabajo"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="description">Descripción</Label>
                  <Textarea
                    id="description"
                    value={formData.description || ""}
                    onChange={(e) => handleInputChange("description", e.target.value)}
                    placeholder="Descripción detallada del trabajo"
                    className="min-h-[100px]"
                  />
                </div>
              </CardContent>
            </Card>

            {/* Status and Priority */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Estado y Prioridad</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label>Estado</Label>
                    <Select 
                      value={formData.status} 
                      onValueChange={(value) => handleInputChange("status", value)}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Seleccionar estado" />
                      </SelectTrigger>
                      <SelectContent>
                        {statusOptions.map((status) => (
                          <SelectItem key={status.value} value={status.value}>
                            {status.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label>Prioridad</Label>
                    <Select 
                      value={formData.priority} 
                      onValueChange={(value) => handleInputChange("priority", value)}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Seleccionar prioridad" />
                      </SelectTrigger>
                      <SelectContent>
                        {priorityOptions.map((priority) => (
                          <SelectItem key={priority.value} value={priority.value}>
                            <div className="flex items-center gap-2">
                              <div className={`h-2 w-2 rounded-full ${priority.color}`} />
                              {priority.label}
                            </div>
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  {ticket?.type === "evaluation" && (
                    <div className="space-y-2">
                      <Label>Severidad</Label>
                      <Select 
                        value={formData.severity} 
                        onValueChange={(value) => handleInputChange("severity", value)}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Seleccionar severidad" />
                        </SelectTrigger>
                        <SelectContent>
                          {severityOptions.map((severity) => (
                            <SelectItem key={severity.value} value={severity.value}>
                              {severity.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Assignment */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <User className="h-5 w-5 text-primary" />
                  Asignación
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <Label>Asignado a</Label>
                  <Select 
                    value={formData.assignedTo} 
                    onValueChange={(value) => handleInputChange("assignedTo", value)}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Seleccionar técnico" />
                    </SelectTrigger>
                    <SelectContent>
                      {availableUsers.map((user) => (
                        <SelectItem key={user.id} value={user.name}>
                          <div>
                            <p className="font-medium">{user.name}</p>
                            <p className="text-sm text-muted-foreground">{user.role}</p>
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>

            {/* Dates */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <CalendarIcon className="h-5 w-5 text-primary" />
                  Fechas Importantes
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {(ticket?.type === "maintenance" || ticket?.scheduledDate) && (
                    <div className="space-y-2">
                      <Label>Fecha Programada</Label>
                      <Popover>
                        <PopoverTrigger asChild>
                          <Button variant="outline" className="w-full justify-start text-left">
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {scheduledDate ? formatDate(scheduledDate) : "Seleccionar fecha"}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0">
                          <Calendar
                            mode="single"
                            selected={scheduledDate}
                            onSelect={setScheduledDate}
                            initialFocus
                          />
                        </PopoverContent>
                      </Popover>
                    </div>
                  )}

                  {(ticket?.type === "evaluation" || ticket?.evaluationDate) && (
                    <div className="space-y-2">
                      <Label>Fecha de Evaluación</Label>
                      <Popover>
                        <PopoverTrigger asChild>
                          <Button variant="outline" className="w-full justify-start text-left">
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {evaluationDate ? formatDate(evaluationDate) : "Seleccionar fecha"}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0">
                          <Calendar
                            mode="single"
                            selected={evaluationDate}
                            onSelect={setEvaluationDate}
                            initialFocus
                          />
                        </PopoverContent>
                      </Popover>
                    </div>
                  )}

                  {ticket?.dueDate && (
                    <div className="space-y-2">
                      <Label>Fecha Límite</Label>
                      <Popover>
                        <PopoverTrigger asChild>
                          <Button variant="outline" className="w-full justify-start text-left">
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {dueDate ? formatDate(dueDate) : "Seleccionar fecha"}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0">
                          <Calendar
                            mode="single"
                            selected={dueDate}
                            onSelect={setDueDate}
                            initialFocus
                          />
                        </PopoverContent>
                      </Popover>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Costs and Hours */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <DollarSign className="h-5 w-5 text-primary" />
                  Costos y Tiempos
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="estimatedCost">Costo Estimado ($)</Label>
                    <Input
                      id="estimatedCost"
                      type="number"
                      step="0.01"
                      value={formData.estimatedCost || ""}
                      onChange={(e) => handleInputChange("estimatedCost", parseFloat(e.target.value) || 0)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="actualCost">Costo Real ($)</Label>
                    <Input
                      id="actualCost"
                      type="number"
                      step="0.01"
                      value={formData.actualCost || ""}
                      onChange={(e) => handleInputChange("actualCost", parseFloat(e.target.value) || 0)}
                    />
                  </div>
                  {ticket?.type === "maintenance" && (
                    <>
                      <div className="space-y-2">
                        <Label htmlFor="estimatedHours">Horas Estimadas</Label>
                        <Input
                          id="estimatedHours"
                          type="number"
                          step="0.5"
                          value={formData.estimatedHours || ""}
                          onChange={(e) => handleInputChange("estimatedHours", parseFloat(e.target.value) || 0)}
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="actualHours">Horas Trabajadas</Label>
                        <Input
                          id="actualHours"
                          type="number"
                          step="0.5"
                          value={formData.actualHours || ""}
                          onChange={(e) => handleInputChange("actualHours", parseFloat(e.target.value) || 0)}
                        />
                      </div>
                    </>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Insurance Information (for evaluations) */}
            {ticket?.type === "evaluation" && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                    <Shield className="h-5 w-5 text-primary" />
                    Información de Seguro
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center space-x-2">
                    <Switch
                      id="hasInsurance"
                      checked={formData.hasInsurance}
                      onCheckedChange={(checked) => handleInputChange("hasInsurance", checked)}
                    />
                    <Label htmlFor="hasInsurance">Tiene cobertura de seguro</Label>
                  </div>

                  {formData.hasInsurance && (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="insuranceCompany">Aseguradora</Label>
                        <Input
                          id="insuranceCompany"
                          value={formData.insuranceCompany || ""}
                          onChange={(e) => handleInputChange("insuranceCompany", e.target.value)}
                          placeholder="Nombre de la aseguradora"
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="insuranceCase">Número de Caso</Label>
                        <Input
                          id="insuranceCase"
                          value={formData.insuranceCase || ""}
                          onChange={(e) => handleInputChange("insuranceCase", e.target.value)}
                          placeholder="Ej: INS-2024-001"
                        />
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            )}
          </div>
        </ScrollArea>

        <DialogFooter className="flex justify-between pt-6">
          <Button variant="outline" onClick={onClose} disabled={isLoading}>
            <X className="h-4 w-4 mr-2" />
            Cancelar
          </Button>
          <Button 
            onClick={handleSave} 
            disabled={isLoading}
            className="gradient-primary"
          >
            {isLoading ? (
              <>
                <div className="h-4 w-4 mr-2 animate-spin rounded-full border-2 border-background border-t-transparent" />
                Guardando...
              </>
            ) : (
              <>
                <Save className="h-4 w-4 mr-2" />
                Guardar Cambios
              </>
            )}
          </Button>
        </DialogFooter>
      
      </DialogContent>
    </Dialog>
  );
}