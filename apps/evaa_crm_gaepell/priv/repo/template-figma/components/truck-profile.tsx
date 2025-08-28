import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { StatusBadge } from "./status-badge";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { 
  Edit,
  Camera,
  FileText,
  Wrench,
  Calendar,
  MapPin,
  Fuel,
  Gauge,
  Download,
  Plus,
  User,
  Clock,
  DollarSign,
  Truck
} from "lucide-react";

// Mock data
const truckData = {
  id: "TRK-001",
  plate: "ABC-123",
  brand: "Volvo",
  model: "FH 460",
  year: 2021,
  vin: "YV2A4A20004567890",
  status: "active",
  mileage: 125000,
  lastMaintenance: "2024-01-15",
  nextMaintenance: "2024-04-15",
  fuelType: "Diesel",
  location: "Terminal Norte",
  driver: "Juan Pérez",
  images: [
    "https://images.unsplash.com/photo-1753579167765-d88ba3719f96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMGZsZWV0JTIwY29tbWVyY2lhbCUyMHZlaGljbGVzfGVufDF8fHx8MTc1NTQxMjU5MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
    "https://images.unsplash.com/photo-1734477127040-c5845f5af500?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0cnVjayUyMG1haW50ZW5hbmNlJTIwcmVwYWlyJTIwZ2FyYWdlfGVufDF8fHx8MTc1NTQxMjY0MXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
  ]
};

const maintenanceHistory = [
  {
    id: "MNT-001",
    type: "Mantenimiento Preventivo",
    date: "2024-01-15",
    status: "completed" as const,
    description: "Cambio de aceite y filtros",
    cost: 1250.00,
    technician: "Carlos García"
  },
  {
    id: "MNT-002",
    type: "Reparación",
    date: "2023-12-10",
    status: "completed" as const,
    description: "Reparación sistema de frenos",
    cost: 3500.00,
    technician: "María López"
  },
  {
    id: "MNT-003",
    type: "Inspección",
    date: "2023-11-05",
    status: "completed" as const,
    description: "Inspección técnica vehicular",
    cost: 450.00,
    technician: "Luis Rodríguez"
  }
];

const documents = [
  {
    id: "DOC-001",
    name: "Certificado de Inspección Técnica",
    type: "PDF",
    date: "2024-01-10",
    size: "2.5 MB"
  },
  {
    id: "DOC-002",
    name: "Póliza de Seguro",
    type: "PDF",
    date: "2024-01-01",
    size: "1.8 MB"
  },
  {
    id: "DOC-003",
    name: "Manual del Propietario",
    type: "PDF",
    date: "2023-12-15",
    size: "5.2 MB"
  }
];

const notes = [
  {
    id: "NOTE-001",
    content: "Camión presenta ligero ruido en el motor al acelerar. Revisar en próximo mantenimiento.",
    author: "Juan Pérez",
    date: "2024-01-18"
  },
  {
    id: "NOTE-002",
    content: "Reemplazados neumáticos traseros izquierdos por desgaste irregular.",
    author: "Carlos García",
    date: "2024-01-15"
  }
];

interface TruckProfileProps {
  truckId?: string;
  onNavigate?: (section: string, id?: string) => void;
}

export function TruckProfile({ truckId, onNavigate }: TruckProfileProps) {
  const [activeTab, setActiveTab] = useState("overview");

  return (
    <div className="space-y-8">
      {/* Header Hero */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-600 via-purple-600 to-blue-800 p-8 text-white shadow-xl">
        <div className="absolute inset-0 bg-black/20"></div>
        <div className="relative z-10 flex items-center justify-between">
          <div className="flex items-center gap-6">
            <div className="relative">
              <ImageWithFallback
                src={truckData.images[0]}
                alt={truckData.model}
                className="h-24 w-24 rounded-2xl object-cover border-4 border-white/20 shadow-xl"
              />
              <div className="absolute -bottom-2 -right-2 h-8 w-8 rounded-full bg-white flex items-center justify-center shadow-lg">
                <Truck className="h-4 w-4 text-blue-600" />
              </div>
            </div>
            <div>
              <h1 className="text-3xl font-bold mb-2">{truckData.plate}</h1>
              <p className="text-xl text-white/80 mb-2">{truckData.brand} {truckData.model} ({truckData.year})</p>
              <div className="flex items-center gap-4">
                <Badge 
                  className={truckData.status === "active" 
                    ? "bg-green-500 text-white border-0 shadow-lg" 
                    : "bg-orange-500 text-white border-0 shadow-lg"
                  }
                >
                  {truckData.status === "active" ? "Activo" : "Mantenimiento"}
                </Badge>
                <div className="flex items-center gap-1 text-white/80">
                  <MapPin className="h-4 w-4" />
                  <span>{truckData.location}</span>
                </div>
              </div>
            </div>
          </div>
          <div className="flex gap-3">
            <Button variant="outline" className="bg-white/10 border-white/20 text-white hover:bg-white/20">
              <Edit className="h-4 w-4 mr-2" />
              Editar
            </Button>
            <Button className="bg-white text-blue-600 hover:bg-white/90 shadow-lg">
              <Plus className="h-4 w-4 mr-2" />
              Nuevo Ticket
            </Button>
          </div>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover-lift bg-card dark:bg-card">
          <CardContent className="p-6 text-center">
            <div className="h-12 w-12 rounded-xl gradient-info flex items-center justify-center mx-auto mb-3 shadow-lg">
              <Gauge className="h-6 w-6 text-white" />
            </div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-1">{truckData.mileage.toLocaleString('es-ES')}</div>
            <p className="text-sm text-slate-600 dark:text-slate-400">Kilómetros</p>
          </CardContent>
        </Card>
        
        <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover-lift bg-card dark:bg-card">
          <CardContent className="p-6 text-center">
            <div className="h-12 w-12 rounded-xl gradient-success flex items-center justify-center mx-auto mb-3 shadow-lg">
              <Calendar className="h-6 w-6 text-white" />
            </div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-1">15</div>
            <p className="text-sm text-slate-600 dark:text-slate-400">Días hasta mantenimiento</p>
          </CardContent>
        </Card>
        
        <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover-lift bg-card dark:bg-card">
          <CardContent className="p-6 text-center">
            <div className="h-12 w-12 rounded-xl gradient-warning flex items-center justify-center mx-auto mb-3 shadow-lg">
              <Fuel className="h-6 w-6 text-white" />
            </div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-1">85%</div>
            <p className="text-sm text-slate-600 dark:text-slate-400">Eficiencia combustible</p>
          </CardContent>
        </Card>
        
        <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover-lift bg-card dark:bg-card">
          <CardContent className="p-6 text-center">
            <div className="h-12 w-12 rounded-xl gradient-primary flex items-center justify-center mx-auto mb-3 shadow-lg">
              <User className="h-6 w-6 text-white" />
            </div>
            <div className="text-lg font-bold text-slate-900 dark:text-slate-100 mb-1">{truckData.driver}</div>
            <p className="text-sm text-slate-600 dark:text-slate-400">Conductor asignado</p>
          </CardContent>
        </Card>
      </div>

      {/* Main Content Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-5 bg-slate-100 dark:bg-slate-800 rounded-xl p-1">
          <TabsTrigger value="overview" className="rounded-lg data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700 data-[state=active]:shadow-md text-slate-700 dark:text-slate-300 data-[state=active]:text-slate-900 dark:data-[state=active]:text-slate-100">
            Resumen
          </TabsTrigger>
          <TabsTrigger value="maintenance" className="rounded-lg data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700 data-[state=active]:shadow-md text-slate-700 dark:text-slate-300 data-[state=active]:text-slate-900 dark:data-[state=active]:text-slate-100">
            Mantenimiento
          </TabsTrigger>
          <TabsTrigger value="documents" className="rounded-lg data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700 data-[state=active]:shadow-md text-slate-700 dark:text-slate-300 data-[state=active]:text-slate-900 dark:data-[state=active]:text-slate-100">
            Documentos
          </TabsTrigger>
          <TabsTrigger value="photos" className="rounded-lg data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700 data-[state=active]:shadow-md text-slate-700 dark:text-slate-300 data-[state=active]:text-slate-900 dark:data-[state=active]:text-slate-100">
            Fotos
          </TabsTrigger>
          <TabsTrigger value="notes" className="rounded-lg data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700 data-[state=active]:shadow-md text-slate-700 dark:text-slate-300 data-[state=active]:text-slate-900 dark:data-[state=active]:text-slate-100">
            Notas
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6 mt-8">
          {/* Technical Info */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
              <CardHeader className="bg-gradient-to-r from-slate-50 to-blue-50 dark:from-slate-800/50 dark:to-blue-900/20 rounded-t-xl">
                <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Información Técnica</CardTitle>
              </CardHeader>
              <CardContent className="p-6 space-y-4">
                <div className="flex items-center justify-between py-2 border-b border-slate-100 dark:border-slate-700">
                  <span className="text-slate-600 dark:text-slate-400">VIN:</span>
                  <span className="font-mono text-sm font-medium text-slate-900 dark:text-slate-100">{truckData.vin}</span>
                </div>
                <div className="flex items-center justify-between py-2 border-b border-slate-100 dark:border-slate-700">
                  <span className="text-slate-600 dark:text-slate-400">Combustible:</span>
                  <span className="font-medium text-slate-900 dark:text-slate-100">{truckData.fuelType}</span>
                </div>
                <div className="flex items-center justify-between py-2">
                  <span className="text-slate-600 dark:text-slate-400">Año:</span>
                  <span className="font-medium text-slate-900 dark:text-slate-100">{truckData.year}</span>
                </div>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
              <CardHeader className="bg-gradient-to-r from-slate-50 to-green-50 dark:from-slate-800/50 dark:to-green-900/20 rounded-t-xl">
                <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Próximo Mantenimiento</CardTitle>
              </CardHeader>
              <CardContent className="p-6">
                <div className="text-center">
                  <div className="text-3xl font-bold text-green-600 dark:text-green-400 mb-2">15</div>
                  <p className="text-slate-600 dark:text-slate-400 mb-4">Días restantes</p>
                  <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-3">
                    <div className="flex items-center gap-2 text-sm text-green-700 dark:text-green-300">
                      <Calendar className="h-4 w-4" />
                      <span>{new Date(truckData.nextMaintenance).toLocaleDateString('es-ES')}</span>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
              <CardHeader className="bg-gradient-to-r from-slate-50 to-purple-50 dark:from-slate-800/50 dark:to-purple-900/20 rounded-t-xl">
                <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Estado Operativo</CardTitle>
              </CardHeader>
              <CardContent className="p-6">
                <div className="space-y-4">
                  <div className="flex items-center gap-3">
                    <div className="h-3 w-3 rounded-full bg-green-500"></div>
                    <span className="text-sm text-slate-700 dark:text-slate-300">Motor: Óptimo</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="h-3 w-3 rounded-full bg-green-500"></div>
                    <span className="text-sm text-slate-700 dark:text-slate-300">Frenos: Óptimo</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="h-3 w-3 rounded-full bg-yellow-500"></div>
                    <span className="text-sm text-slate-700 dark:text-slate-300">Neumáticos: Revisar</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Recent Activity */}
          <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
            <CardHeader className="bg-gradient-to-r from-slate-50 to-indigo-50 dark:from-slate-800/50 dark:to-indigo-900/20 rounded-t-xl">
              <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Actividad Reciente</CardTitle>
            </CardHeader>
            <CardContent className="p-6">
              <div className="space-y-4">
                {maintenanceHistory.slice(0, 3).map((item) => (
                  <div key={item.id} className="flex items-center space-x-4 p-4 border border-slate-200/60 dark:border-slate-700/60 rounded-xl hover:shadow-md transition-all duration-200 hover-lift bg-white dark:bg-slate-800/50">
                    <div className="h-12 w-12 rounded-xl gradient-primary flex items-center justify-center shadow-lg">
                      <Wrench className="h-5 w-5 text-white" />
                    </div>
                    <div className="flex-1">
                      <h4 className="font-semibold text-slate-900 dark:text-slate-100">{item.type}</h4>
                      <p className="text-sm text-slate-600 dark:text-slate-400">{item.description}</p>
                      <div className="flex items-center gap-4 mt-2 text-xs text-slate-500 dark:text-slate-400">
                        <div className="flex items-center gap-1">
                          <Calendar className="h-3 w-3" />
                          <span>{new Date(item.date).toLocaleDateString('es-ES')}</span>
                        </div>
                        <div className="flex items-center gap-1">
                          <User className="h-3 w-3" />
                          <span>{item.technician}</span>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <StatusBadge status={item.status} />
                      <div className="flex items-center gap-1 mt-2 text-sm font-medium text-slate-700 dark:text-slate-300">
                        <DollarSign className="h-3 w-3" />
                        <span>{item.cost.toLocaleString('es-ES')}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="maintenance" className="space-y-6 mt-8">
          <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
            <CardHeader className="bg-gradient-to-r from-slate-50 to-blue-50 dark:from-slate-800/50 dark:to-blue-900/20 rounded-t-xl">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Historial de Mantenimiento</CardTitle>
                  <CardDescription className="text-slate-600 dark:text-slate-400">Registro completo de servicios y reparaciones</CardDescription>
                </div>
                <Button 
                  onClick={() => onNavigate?.("tickets")}
                  className="gradient-primary text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Nuevo Ticket
                </Button>
              </div>
            </CardHeader>
            <CardContent className="p-6">
              <div className="space-y-4">
                {maintenanceHistory.map((item) => (
                  <div key={item.id} className="flex items-center space-x-4 p-6 border border-slate-200/60 dark:border-slate-700/60 rounded-xl hover:shadow-md transition-all duration-200 hover-lift bg-white dark:bg-slate-800/50">
                    <div className="h-14 w-14 rounded-xl gradient-primary flex items-center justify-center shadow-lg">
                      <Wrench className="h-6 w-6 text-white" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h4 className="font-semibold text-slate-900 dark:text-slate-100 text-lg">{item.type}</h4>
                        <StatusBadge status={item.status} />
                      </div>
                      <p className="text-slate-600 dark:text-slate-400 mb-3">{item.description}</p>
                      <div className="flex items-center gap-6 text-sm text-slate-500 dark:text-slate-400">
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4" />
                          <span>{new Date(item.date).toLocaleDateString('es-ES')}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <User className="h-4 w-4" />
                          <span>{item.technician}</span>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="flex items-center gap-1 text-lg font-semibold text-slate-900 dark:text-slate-100 mb-3">
                        <DollarSign className="h-5 w-5" />
                        <span>{item.cost.toLocaleString('es-ES')}</span>
                      </div>
                      <Button variant="outline" size="sm" className="border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800">
                        Ver Detalles
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="documents" className="space-y-6 mt-8">
          <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
            <CardHeader className="bg-gradient-to-r from-slate-50 to-green-50 dark:from-slate-800/50 dark:to-green-900/20 rounded-t-xl">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Documentos</CardTitle>
                  <CardDescription className="text-slate-600 dark:text-slate-400">Archivos y documentos asociados al camión</CardDescription>
                </div>
                <Button className="gradient-success text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200">
                  <Plus className="h-4 w-4 mr-2" />
                  Subir Documento
                </Button>
              </div>
            </CardHeader>
            <CardContent className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {documents.map((doc) => (
                  <div key={doc.id} className="p-4 border border-slate-200/60 dark:border-slate-700/60 rounded-xl hover:shadow-md transition-all duration-200 hover-lift bg-white dark:bg-slate-800/50">
                    <div className="flex items-start gap-3">
                      <div className="h-12 w-12 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
                        <FileText className="h-6 w-6 text-red-600 dark:text-red-400" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-medium text-slate-900 dark:text-slate-100 truncate">{doc.name}</h4>
                        <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">
                          {doc.type} • {doc.size}
                        </p>
                        <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                          {new Date(doc.date).toLocaleDateString('es-ES')}
                        </p>
                      </div>
                    </div>
                    <Button variant="outline" size="sm" className="w-full mt-3 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800">
                      <Download className="h-3 w-3 mr-2" />
                      Descargar
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="photos" className="space-y-6 mt-8">
          <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
            <CardHeader className="bg-gradient-to-r from-slate-50 to-purple-50 dark:from-slate-800/50 dark:to-purple-900/20 rounded-t-xl">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Galería de Fotos</CardTitle>
                  <CardDescription className="text-slate-600 dark:text-slate-400">Imágenes del camión y documentación visual</CardDescription>
                </div>
                <Button className="bg-purple-600 hover:bg-purple-700 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200">
                  <Camera className="h-4 w-4 mr-2" />
                  Subir Foto
                </Button>
              </div>
            </CardHeader>
            <CardContent className="p-6">
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                {truckData.images.map((image, index) => (
                  <div key={index} className="aspect-square group cursor-pointer">
                    <ImageWithFallback
                      src={image}
                      alt={`${truckData.plate} - Foto ${index + 1}`}
                      className="w-full h-full object-cover rounded-xl border-2 border-slate-200 dark:border-slate-700 shadow-md hover:shadow-xl transition-all duration-300 group-hover:scale-105"
                    />
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notes" className="space-y-6 mt-8">
          <Card className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-card dark:bg-card">
            <CardHeader className="bg-gradient-to-r from-slate-50 to-yellow-50 dark:from-slate-800/50 dark:to-yellow-900/20 rounded-t-xl">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-lg text-slate-900 dark:text-slate-100">Notas del Camión</CardTitle>
                  <CardDescription className="text-slate-600 dark:text-slate-400">Observaciones y comentarios importantes</CardDescription>
                </div>
                <Button className="bg-yellow-600 hover:bg-yellow-700 text-white border-0 shadow-lg hover:shadow-xl transition-all duration-200">
                  <Plus className="h-4 w-4 mr-2" />
                  Agregar Nota
                </Button>
              </div>
            </CardHeader>
            <CardContent className="p-6">
              <div className="space-y-4">
                {notes.map((note) => (
                  <div key={note.id} className="p-4 border border-slate-200/60 dark:border-slate-700/60 rounded-xl hover:shadow-md transition-all duration-200 hover-lift bg-white dark:bg-slate-800/50">
                    <p className="text-slate-800 dark:text-slate-200 mb-3">{note.content}</p>
                    <div className="flex items-center justify-between text-sm">
                      <div className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                        <User className="h-4 w-4" />
                        <span>Por: {note.author}</span>
                      </div>
                      <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400">
                        <Clock className="h-4 w-4" />
                        <span>{new Date(note.date).toLocaleDateString('es-ES')}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}