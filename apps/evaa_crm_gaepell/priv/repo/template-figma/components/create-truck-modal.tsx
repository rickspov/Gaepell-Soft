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
import { Checkbox } from "./ui/checkbox";
import { toast } from "sonner@2.0.3";
import { 
  Calendar as CalendarIcon,
  Truck,
  User,
  FileText,
  Settings,
  MapPin,
  DollarSign,
  AlertTriangle,
  Shield,
  Camera,
  Upload,
  Save,
  X,
  Plus,
  Wrench,
  Fuel,
  Gauge,
  Weight,
  Palette,
  Hash
} from "lucide-react";

interface CreateTruckModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (truckData: any) => void;
}

// Datos mock para selecciones
const truckBrands = [
  "Volvo", "Scania", "Mercedes-Benz", "MAN", "DAF", "Iveco", "Renault", 
  "Freightliner", "Kenworth", "Peterbilt", "Mack", "International"
];

const fuelTypes = [
  { value: "diesel", label: "Diésel" },
  { value: "gasoline", label: "Gasolina" },
  { value: "hybrid", label: "Híbrido" },
  { value: "electric", label: "Eléctrico" },
  { value: "cng", label: "GNC" }
];

const transmissionTypes = [
  { value: "manual", label: "Manual" },
  { value: "automatic", label: "Automática" },
  { value: "semi-automatic", label: "Semi-automática" }
];

const truckCategories = [
  { value: "light", label: "Ligero (< 3.5 ton)" },
  { value: "medium", label: "Mediano (3.5 - 12 ton)" },
  { value: "heavy", label: "Pesado (> 12 ton)" },
  { value: "trailer", label: "Tractocamión" }
];

const statusOptions = [
  { value: "active", label: "Activo", color: "bg-success" },
  { value: "maintenance", label: "En Mantenimiento", color: "bg-warning" },
  { value: "out-of-service", label: "Fuera de Servicio", color: "bg-destructive" },
  { value: "inspection", label: "En Inspección", color: "bg-info" }
];

// Helper function to format dates
const formatDate = (date: Date) => {
  return date.toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

// Custom styles for required fields
const requiredLabelStyles = "after:content-['*'] after:text-destructive after:ml-1";

export function CreateTruckModal({ isOpen, onClose, onSave }: CreateTruckModalProps) {
  const [formData, setFormData] = useState<any>({
    // Información básica
    licensePlate: "",
    brand: "",
    model: "",
    year: new Date().getFullYear(),
    color: "",
    vin: "",
    category: "medium",
    
    // Especificaciones técnicas
    engine: "",
    transmission: "manual",
    fuelType: "diesel",
    fuelCapacity: 0,
    loadCapacity: 0,
    mileage: 0,
    
    // Información del conductor/propietario
    assignedDriver: "",
    driverPhone: "",
    driverLicense: "",
    owner: "",
    ownerContact: "",
    
    // Estado y fechas
    status: "active",
    purchasePrice: 0,
    marketValue: 0,
    location: "",
    homeBase: "",
    
    // Documentación
    hasInsurance: true,
    insuranceCompany: "",
    insurancePolicy: "",
    hasPermits: true,
    permitDetails: "",
    
    // Mantenimiento
    lastService: null,
    nextService: null,
    lastInspection: null,
    nextInspection: null,
    
    // Adicionales
    hasGPS: true,
    hasDashcam: false,
    hasRefrigeration: false,
    hasLiftGate: false,
    notes: ""
  });

  const [purchaseDate, setPurchaseDate] = useState<Date | undefined>(undefined);
  const [lastServiceDate, setLastServiceDate] = useState<Date | undefined>(undefined);
  const [nextServiceDate, setNextServiceDate] = useState<Date | undefined>(undefined);
  const [lastInspectionDate, setLastInspectionDate] = useState<Date | undefined>(undefined);
  const [nextInspectionDate, setNextInspectionDate] = useState<Date | undefined>(undefined);
  const [insuranceExpiryDate, setInsuranceExpiryDate] = useState<Date | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(false);

  const generateTruckId = () => {
    const prefix = "TRK";
    const timestamp = Date.now().toString().slice(-6);
    return `${prefix}-${timestamp}`;
  };

  const handleSave = async () => {
    // Validaciones básicas
    if (!formData.licensePlate.trim()) {
      toast.error("Placa requerida", {
        description: "Por favor ingresa la placa del camión."
      });
      return;
    }

    if (!formData.brand.trim() || !formData.model.trim()) {
      toast.error("Marca y modelo requeridos", {
        description: "Por favor completa la marca y modelo del camión."
      });
      return;
    }

    setIsLoading(true);
    
    try {
      const truckId = generateTruckId();
      
      const newTruck = {
        id: truckId,
        ...formData,
        purchaseDate: purchaseDate?.toISOString(),
        lastService: lastServiceDate?.toISOString(),
        nextService: nextServiceDate?.toISOString(),
        lastInspection: lastInspectionDate?.toISOString(),
        nextInspection: nextInspectionDate?.toISOString(),
        insuranceExpiry: insuranceExpiryDate?.toISOString(),
        createdAt: new Date().toISOString(),
        // Generar datos adicionales para el perfil
        totalTickets: 0,
        activeTickets: 0,
        completedTickets: 0,
        maintenanceCost: 0,
        efficiency: 95,
        uptime: 98
      };

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      onSave(newTruck);
      toast.success("Camión registrado exitosamente", {
        description: `El camión ${formData.licensePlate} (${truckId}) ha sido añadido a la flota.`
      });
      onClose();
      
      // Reset form
      setFormData({});
      setPurchaseDate(undefined);
      setLastServiceDate(undefined);
      setNextServiceDate(undefined);
      setLastInspectionDate(undefined);
      setNextInspectionDate(undefined);
      setInsuranceExpiryDate(undefined);
      
    } catch (error) {
      toast.error("Error al registrar camión", {
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

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-5xl max-h-[95vh] overflow-hidden">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <Truck className="h-6 w-6 text-primary" />
            Registrar Nuevo Camión
            <Badge variant="outline" className="ml-2 gradient-primary text-primary-foreground">
              Nuevo Registro
            </Badge>
          </DialogTitle>
          <DialogDescription>
            Completa la información del camión para añadirlo a la flota. Los campos marcados son obligatorios.
          </DialogDescription>
        </DialogHeader>

        <ScrollArea className="max-h-[calc(95vh-200px)] overflow-auto">
          <div className="space-y-6 pr-6">
            
            {/* Información Básica */}
            <Card className="glass-effect">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Hash className="h-5 w-5 text-primary" />
                  Información Básica
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="licensePlate" className={requiredLabelStyles}>Placa</Label>
                    <Input
                      id="licensePlate"
                      value={formData.licensePlate || ""}
                      onChange={(e) => handleInputChange("licensePlate", e.target.value.toUpperCase())}
                      placeholder="Ej: ABC-123"
                      className="font-mono"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="brand" className={requiredLabelStyles}>Marca</Label>
                    <Select 
                      value={formData.brand} 
                      onValueChange={(value) => handleInputChange("brand", value)}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Seleccionar marca" />
                      </SelectTrigger>
                      <SelectContent>
                        {truckBrands.map((brand) => (
                          <SelectItem key={brand} value={brand}>
                            {brand}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="model" className={requiredLabelStyles}>Modelo</Label>
                    <Input
                      id="model"
                      value={formData.model || ""}
                      onChange={(e) => handleInputChange("model", e.target.value)}
                      placeholder="Modelo del camión"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="year">Año</Label>
                    <Input
                      id="year"
                      type="number"
                      min="1900"
                      max={new Date().getFullYear() + 1}
                      value={formData.year || ""}
                      onChange={(e) => handleInputChange("year", parseInt(e.target.value) || new Date().getFullYear())}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="color">Color</Label>
                    <Input
                      id="color"
                      value={formData.color || ""}
                      onChange={(e) => handleInputChange("color", e.target.value)}
                      placeholder="Ej: Blanco"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="vin">VIN</Label>
                    <Input
                      id="vin"
                      value={formData.vin || ""}
                      onChange={(e) => handleInputChange("vin", e.target.value.toUpperCase())}
                      placeholder="Número de chasis"
                      className="font-mono"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Categoría</Label>
                    <Select 
                      value={formData.category} 
                      onValueChange={(value) => handleInputChange("category", value)}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {truckCategories.map((category) => (
                          <SelectItem key={category.value} value={category.value}>
                            {category.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Especificaciones Técnicas */}
            <Card className="glass-effect">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Settings className="h-5 w-5 text-primary" />
                  Especificaciones Técnicas
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="engine">Motor</Label>
                    <Input
                      id="engine"
                      value={formData.engine || ""}
                      onChange={(e) => handleInputChange("engine", e.target.value)}
                      placeholder="Ej: D13K 460 HP"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Transmisión</Label>
                    <Select 
                      value={formData.transmission} 
                      onValueChange={(value) => handleInputChange("transmission", value)}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {transmissionTypes.map((type) => (
                          <SelectItem key={type.value} value={type.value}>
                            {type.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="space-y-2">
                    <Label>Combustible</Label>
                    <Select 
                      value={formData.fuelType} 
                      onValueChange={(value) => handleInputChange("fuelType", value)}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {fuelTypes.map((fuel) => (
                          <SelectItem key={fuel.value} value={fuel.value}>
                            {fuel.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="fuelCapacity">Capacidad Combustible (L)</Label>
                    <Input
                      id="fuelCapacity"
                      type="number"
                      step="0.1"
                      value={formData.fuelCapacity || ""}
                      onChange={(e) => handleInputChange("fuelCapacity", parseFloat(e.target.value) || 0)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="loadCapacity">Capacidad Carga (ton)</Label>
                    <Input
                      id="loadCapacity"
                      type="number"
                      step="0.1"
                      value={formData.loadCapacity || ""}
                      onChange={(e) => handleInputChange("loadCapacity", parseFloat(e.target.value) || 0)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="mileage">Kilometraje</Label>
                    <Input
                      id="mileage"
                      type="number"
                      value={formData.mileage || ""}
                      onChange={(e) => handleInputChange("mileage", parseInt(e.target.value) || 0)}
                    />
                  </div>
                </div>

                {/* Equipment Checkboxes */}
                <div className="space-y-3">
                  <Label>Equipamiento Adicional</Label>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="hasGPS"
                        checked={formData.hasGPS}
                        onCheckedChange={(checked) => handleInputChange("hasGPS", checked)}
                      />
                      <Label htmlFor="hasGPS" className="text-sm">GPS</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="hasDashcam"
                        checked={formData.hasDashcam}
                        onCheckedChange={(checked) => handleInputChange("hasDashcam", checked)}
                      />
                      <Label htmlFor="hasDashcam" className="text-sm">Cámara de tablero</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="hasRefrigeration"
                        checked={formData.hasRefrigeration}
                        onCheckedChange={(checked) => handleInputChange("hasRefrigeration", checked)}
                      />
                      <Label htmlFor="hasRefrigeration" className="text-sm">Refrigeración</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="hasLiftGate"
                        checked={formData.hasLiftGate}
                        onCheckedChange={(checked) => handleInputChange("hasLiftGate", checked)}
                      />
                      <Label htmlFor="hasLiftGate" className="text-sm">Compuerta elevadora</Label>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Conductor y Propietario */}
            <Card className="glass-effect">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <User className="h-5 w-5 text-primary" />
                  Conductor y Propietario
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="assignedDriver">Conductor Asignado</Label>
                    <Input
                      id="assignedDriver"
                      value={formData.assignedDriver || ""}
                      onChange={(e) => handleInputChange("assignedDriver", e.target.value)}
                      placeholder="Nombre completo"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="driverPhone">Teléfono Conductor</Label>
                    <Input
                      id="driverPhone"
                      value={formData.driverPhone || ""}
                      onChange={(e) => handleInputChange("driverPhone", e.target.value)}
                      placeholder="+1234567890"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="driverLicense">Licencia</Label>
                    <Input
                      id="driverLicense"
                      value={formData.driverLicense || ""}
                      onChange={(e) => handleInputChange("driverLicense", e.target.value)}
                      placeholder="Número de licencia"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="owner">Propietario</Label>
                    <Input
                      id="owner"
                      value={formData.owner || ""}
                      onChange={(e) => handleInputChange("owner", e.target.value)}
                      placeholder="Nombre/Empresa propietaria"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="ownerContact">Contacto Propietario</Label>
                    <Input
                      id="ownerContact"
                      value={formData.ownerContact || ""}
                      onChange={(e) => handleInputChange("ownerContact", e.target.value)}
                      placeholder="Teléfono/Email"
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Estado y Ubicación */}
            <Card className="glass-effect">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <MapPin className="h-5 w-5 text-primary" />
                  Estado y Ubicación
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Estado Actual</Label>
                    <Select 
                      value={formData.status} 
                      onValueChange={(value) => handleInputChange("status", value)}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {statusOptions.map((status) => (
                          <SelectItem key={status.value} value={status.value}>
                            <div className="flex items-center gap-2">
                              <div className={`h-2 w-2 rounded-full ${status.color}`} />
                              {status.label}
                            </div>
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="location">Ubicación Actual</Label>
                    <Input
                      id="location"
                      value={formData.location || ""}
                      onChange={(e) => handleInputChange("location", e.target.value)}
                      placeholder="Ciudad, dirección"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="homeBase">Base Principal</Label>
                    <Input
                      id="homeBase"
                      value={formData.homeBase || ""}
                      onChange={(e) => handleInputChange("homeBase", e.target.value)}
                      placeholder="Ubicación base"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="purchasePrice">Precio Compra ($)</Label>
                    <Input
                      id="purchasePrice"
                      type="number"
                      step="0.01"
                      value={formData.purchasePrice || ""}
                      onChange={(e) => handleInputChange("purchasePrice", parseFloat(e.target.value) || 0)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="marketValue">Valor Actual ($)</Label>
                    <Input
                      id="marketValue"
                      type="number"
                      step="0.01"
                      value={formData.marketValue || ""}
                      onChange={(e) => handleInputChange("marketValue", parseFloat(e.target.value) || 0)}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Fecha de Compra</Label>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button variant="outline" className="w-full justify-start text-left">
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {purchaseDate ? formatDate(purchaseDate) : "Seleccionar fecha"}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0">
                      <Calendar
                        mode="single"
                        selected={purchaseDate}
                        onSelect={setPurchaseDate}
                        initialFocus
                      />
                    </PopoverContent>
                  </Popover>
                </div>
              </CardContent>
            </Card>

            {/* Documentación y Seguros */}
            <Card className="glass-effect">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Shield className="h-5 w-5 text-primary" />
                  Documentación y Seguros
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center space-x-2">
                  <Switch
                    id="hasInsurance"
                    checked={formData.hasInsurance}
                    onCheckedChange={(checked) => handleInputChange("hasInsurance", checked)}
                  />
                  <Label htmlFor="hasInsurance">Tiene seguro vigente</Label>
                </div>

                {formData.hasInsurance && (
                  <div className="space-y-4 p-4 border rounded-lg">
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
                        <Label htmlFor="insurancePolicy">Número de Póliza</Label>
                        <Input
                          id="insurancePolicy"
                          value={formData.insurancePolicy || ""}
                          onChange={(e) => handleInputChange("insurancePolicy", e.target.value)}
                          placeholder="Número de póliza"
                        />
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Label>Fecha de Vencimiento Seguro</Label>
                      <Popover>
                        <PopoverTrigger asChild>
                          <Button variant="outline" className="w-full justify-start text-left">
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {insuranceExpiryDate ? formatDate(insuranceExpiryDate) : "Seleccionar fecha"}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0">
                          <Calendar
                            mode="single"
                            selected={insuranceExpiryDate}
                            onSelect={setInsuranceExpiryDate}
                            initialFocus
                          />
                        </PopoverContent>
                      </Popover>
                    </div>
                  </div>
                )}

                <div className="flex items-center space-x-2">
                  <Switch
                    id="hasPermits"
                    checked={formData.hasPermits}
                    onCheckedChange={(checked) => handleInputChange("hasPermits", checked)}
                  />
                  <Label htmlFor="hasPermits">Permisos y documentación vigente</Label>
                </div>

                {formData.hasPermits && (
                  <div className="space-y-2">
                    <Label htmlFor="permitDetails">Detalles de Permisos</Label>
                    <Textarea
                      id="permitDetails"
                      value={formData.permitDetails || ""}
                      onChange={(e) => handleInputChange("permitDetails", e.target.value)}
                      placeholder="Descripción de permisos, documentos especiales, etc."
                      className="min-h-[80px]"
                    />
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Programación de Mantenimiento */}
            <Card className="glass-effect">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Wrench className="h-5 w-5 text-primary" />
                  Mantenimiento e Inspecciones
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <h4 className="font-medium">Último Servicio</h4>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button variant="outline" className="w-full justify-start text-left">
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {lastServiceDate ? formatDate(lastServiceDate) : "Fecha último servicio"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                        <Calendar
                          mode="single"
                          selected={lastServiceDate}
                          onSelect={setLastServiceDate}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>

                  <div className="space-y-4">
                    <h4 className="font-medium">Próximo Servicio</h4>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button variant="outline" className="w-full justify-start text-left">
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {nextServiceDate ? formatDate(nextServiceDate) : "Fecha próximo servicio"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                        <Calendar
                          mode="single"
                          selected={nextServiceDate}
                          onSelect={setNextServiceDate}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>

                  <div className="space-y-4">
                    <h4 className="font-medium">Última Inspección</h4>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button variant="outline" className="w-full justify-start text-left">
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {lastInspectionDate ? formatDate(lastInspectionDate) : "Fecha última inspección"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                        <Calendar
                          mode="single"
                          selected={lastInspectionDate}
                          onSelect={setLastInspectionDate}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>

                  <div className="space-y-4">
                    <h4 className="font-medium">Próxima Inspección</h4>
                    <Popover>
                      <PopoverTrigger asChild>
                        <Button variant="outline" className="w-full justify-start text-left">
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {nextInspectionDate ? formatDate(nextInspectionDate) : "Fecha próxima inspección"}
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                        <Calendar
                          mode="single"
                          selected={nextInspectionDate}
                          onSelect={setNextInspectionDate}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Notas Adicionales */}
            <Card className="glass-effect">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="h-5 w-5 text-primary" />
                  Notas Adicionales
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <Label htmlFor="notes">Observaciones</Label>
                  <Textarea
                    id="notes"
                    value={formData.notes || ""}
                    onChange={(e) => handleInputChange("notes", e.target.value)}
                    placeholder="Cualquier información adicional relevante sobre el camión..."
                    className="min-h-[100px]"
                  />
                </div>
              </CardContent>
            </Card>
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
                Registrando...
              </>
            ) : (
              <>
                <Save className="h-4 w-4 mr-2" />
                Registrar Camión
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}