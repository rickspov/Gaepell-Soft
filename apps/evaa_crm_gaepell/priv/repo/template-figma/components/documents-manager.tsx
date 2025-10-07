import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Input } from "./ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger, DropdownMenuSeparator } from "./ui/dropdown-menu";
import { Separator } from "./ui/separator";
import { ScrollArea } from "./ui/scroll-area";
import { UploadDocumentModal } from "./upload-document-modal";
import { DocumentPreviewModal } from "./document-preview-modal";
import { toast } from "sonner@2.0.3";
import { 
  Plus, 
  Search, 
  Filter, 
  FileText, 
  Image, 
  Download, 
  Eye, 
  Trash2, 
  MoreVertical,
  Calendar,
  User,
  Truck,
  AlertTriangle,
  DollarSign,
  ShoppingCart,
  Receipt,
  Paperclip,
  FolderOpen,
  Grid3X3,
  List,
  SortAsc,
  SortDesc
} from "lucide-react";

interface DocumentsManagerProps {
  onNavigate?: (section: string, subsection?: string) => void;
  trucks?: any[];
}

// Mock data para documentos existentes
const mockDocuments = [
  {
    id: "DOC-001",
    title: "Fotos del Volvo FH16 - Exterior",
    description: "Fotografías del estado general del vehículo ABC-123",
    category: "truck-photos",
    associatedTruck: "TRK-001",
    truckPlate: "ABC-123",
    files: [
      { id: "FILE-001", name: "volvo-frontal.jpg", type: "image", size: 2456789, url: "#" },
      { id: "FILE-002", name: "volvo-lateral.jpg", type: "image", size: 2234567, url: "#" },
      { id: "FILE-003", name: "volvo-trasero.jpg", type: "image", size: 2345678, url: "#" }
    ],
    totalFiles: 3,
    totalSize: 7037034,
    tags: ["exterior", "estado", "documentación"],
    createdAt: "2024-02-15T10:30:00Z",
    createdBy: "Carlos García",
    lastModified: "2024-02-15T10:30:00Z"
  },
  {
    id: "DOC-002",
    title: "Factura Repuestos Febrero 2024",
    description: "Factura de compra de filtros y aceites para mantenimiento preventivo",
    category: "invoices",
    associatedTruck: "TRK-002",
    truckPlate: "DEF-456",
    files: [
      { id: "FILE-004", name: "factura-repuestos-feb-2024.pdf", type: "pdf", size: 1234567, url: "#" }
    ],
    totalFiles: 1,
    totalSize: 1234567,
    tags: ["mantenimiento", "repuestos", "febrero"],
    createdAt: "2024-02-10T14:22:00Z",
    createdBy: "Ana Martínez",
    lastModified: "2024-02-10T14:22:00Z"
  },
  {
    id: "DOC-003",
    title: "Evaluación de Daños - Incidente Parking",
    description: "Fotografías del daño menor en el paragolpes trasero",
    category: "damage-photos",
    associatedTruck: "TRK-001",
    truckPlate: "ABC-123",
    files: [
      { id: "FILE-005", name: "dano-paragolpes-1.jpg", type: "image", size: 3456789, url: "#" },
      { id: "FILE-006", name: "dano-paragolpes-2.jpg", type: "image", size: 3234567, url: "#" },
      { id: "FILE-007", name: "reporte-incidente.pdf", type: "pdf", size: 987654, url: "#" }
    ],
    totalFiles: 3,
    totalSize: 7679010,
    tags: ["daño", "paragolpes", "incidente", "parking"],
    createdAt: "2024-02-08T09:15:00Z",
    createdBy: "Luis Rodríguez",
    lastModified: "2024-02-08T09:15:00Z"
  },
  {
    id: "DOC-004",
    title: "Cotización Reparación Motor",
    description: "Cotización para reparación mayor del motor Scania R450",
    category: "quotes",
    associatedTruck: "TRK-002",
    truckPlate: "DEF-456",
    files: [
      { id: "FILE-008", name: "cotizacion-motor-scania.pdf", type: "pdf", size: 2456789, url: "#" },
      { id: "FILE-009", name: "diagnostico-motor.pdf", type: "pdf", size: 1876543, url: "#" }
    ],
    totalFiles: 2,
    totalSize: 4333332,
    tags: ["motor", "reparación", "cotización", "scania"],
    createdAt: "2024-02-05T11:45:00Z",
    createdBy: "Carlos García",
    lastModified: "2024-02-05T11:45:00Z"
  },
  {
    id: "DOC-005",
    title: "Póliza de Seguro Mercedes Actros",
    description: "Documentación del seguro vigente para el Mercedes Actros GHI-789",
    category: "insurance",
    associatedTruck: "TRK-003",
    truckPlate: "GHI-789",
    files: [
      { id: "FILE-010", name: "poliza-seguro-mercedes.pdf", type: "pdf", size: 3456789, url: "#" }
    ],
    totalFiles: 1,
    totalSize: 3456789,
    tags: ["seguro", "póliza", "vigente", "mercedes"],
    createdAt: "2024-01-28T16:20:00Z",
    createdBy: "Ana Martínez",
    lastModified: "2024-01-28T16:20:00Z"
  }
];

// Categorías con iconos y colores
const categoryConfig = {
  "truck-photos": { 
    label: "Fotos del Camión", 
    icon: Truck, 
    color: "bg-blue-500",
    description: "Fotografías del vehículo"
  },
  "damage-photos": { 
    label: "Fotos de Daños", 
    icon: AlertTriangle, 
    color: "bg-red-500",
    description: "Evidencia de daños"
  },
  "purchase-orders": { 
    label: "Órdenes de Compra", 
    icon: ShoppingCart, 
    color: "bg-green-500",
    description: "Órdenes y requisiciones"
  },
  "quotes": { 
    label: "Cotizaciones", 
    icon: DollarSign, 
    color: "bg-yellow-500",
    description: "Cotizaciones de servicios"
  },
  "invoices": { 
    label: "Facturas", 
    icon: Receipt, 
    color: "bg-purple-500",
    description: "Facturas y comprobantes"
  },
  "insurance": { 
    label: "Seguros", 
    icon: FileText, 
    color: "bg-indigo-500",
    description: "Pólizas de seguro"
  },
  "permits": { 
    label: "Permisos", 
    icon: FileText, 
    color: "bg-orange-500",
    description: "Permisos y licencias"
  },
  "maintenance": { 
    label: "Mantenimiento", 
    icon: FileText, 
    color: "bg-teal-500",
    description: "Registros de mantenimiento"
  },
  "others": { 
    label: "Otros", 
    icon: Paperclip, 
    color: "bg-gray-500",
    description: "Documentos diversos"
  }
};

// Función para formatear fechas
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('es-ES', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// Función para formatear tamaño de archivo
const formatFileSize = (bytes: number) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
};

export function DocumentsManager({ onNavigate, trucks = [] }: DocumentsManagerProps) {
  const [documents, setDocuments] = useState(mockDocuments);
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [isPreviewModalOpen, setIsPreviewModalOpen] = useState(false);
  const [selectedDocument, setSelectedDocument] = useState<any>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [selectedTruck, setSelectedTruck] = useState<string>("all");
  const [sortBy, setSortBy] = useState<string>("date-desc");
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");

  // Filtrar documentos
  const filteredDocuments = documents.filter(doc => {
    const matchesSearch = 
      doc.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      doc.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
      doc.tags.some(tag => tag.toLowerCase().includes(searchTerm.toLowerCase())) ||
      doc.truckPlate?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesCategory = selectedCategory === "all" || doc.category === selectedCategory;
    const matchesTruck = selectedTruck === "all" || doc.associatedTruck === selectedTruck || (selectedTruck === "none" && !doc.associatedTruck);
    
    return matchesSearch && matchesCategory && matchesTruck;
  });

  // Ordenar documentos
  const sortedDocuments = [...filteredDocuments].sort((a, b) => {
    switch (sortBy) {
      case "date-desc":
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      case "date-asc":
        return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
      case "name-asc":
        return a.title.localeCompare(b.title);
      case "name-desc":
        return b.title.localeCompare(a.title);
      case "size-desc":
        return b.totalSize - a.totalSize;
      case "size-asc":
        return a.totalSize - b.totalSize;
      default:
        return 0;
    }
  });

  const handleDocumentSave = (documentData: any) => {
    setDocuments(prev => [documentData, ...prev]);
  };

  const handleDeleteDocument = (documentId: string) => {
    setDocuments(prev => prev.filter(doc => doc.id !== documentId));
    toast.success("Documento eliminado", {
      description: "El documento ha sido eliminado correctamente."
    });
  };

  const handleDownloadDocument = (document: any) => {
    toast.success("Descarga iniciada", {
      description: `Descargando ${document.files.length} archivo(s) de "${document.title}".`
    });
  };

  const handleViewDocument = (document: any) => {
    setSelectedDocument(document);
    setIsPreviewModalOpen(true);
  };

  // Estadísticas
  const stats = {
    total: documents.length,
    categories: Object.keys(categoryConfig).map(key => ({
      key,
      count: documents.filter(doc => doc.category === key).length,
      ...categoryConfig[key as keyof typeof categoryConfig]
    })).filter(cat => cat.count > 0),
    totalSize: documents.reduce((acc, doc) => acc + doc.totalSize, 0),
    totalFiles: documents.reduce((acc, doc) => acc + doc.totalFiles, 0)
  };

  return (
    <div className="space-y-4 md:space-y-6">
      <Card className="glass-effect">
        <CardHeader>
          <div className="flex flex-col space-y-4 md:flex-row md:items-center md:justify-between md:space-y-0">
            <div>
              <CardTitle className="flex items-center gap-2 text-lg md:text-xl">
                <FolderOpen className="h-5 w-5 md:h-6 md:w-6 text-primary" />
                Gestión de Documentos
              </CardTitle>
              <CardDescription className="text-sm md:text-base">
                Administra todos los documentos y archivos de la flota
              </CardDescription>
            </div>
            <Button 
              onClick={() => setIsUploadModalOpen(true)}
              className="gradient-primary hover-lift h-11 md:h-10 w-full md:w-auto"
              size="lg"
            >
              <Plus className="h-4 w-4 mr-2" />
              <span className="md:hidden">Subir Documento</span>
              <span className="hidden md:inline">Subir Documento</span>
            </Button>
          </div>
        </CardHeader>

        <CardContent className="space-y-4 md:space-y-6">
          {/* Estadísticas Rápidas */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 md:gap-4 p-3 md:p-4 bg-muted/50 rounded-lg">
            <div className="text-center space-y-1">
              <div className="text-xl md:text-2xl font-bold text-primary">{stats.total}</div>
              <div className="text-xs md:text-sm text-muted-foreground">Documentos</div>
            </div>
            <div className="text-center space-y-1">
              <div className="text-xl md:text-2xl font-bold text-info">{stats.totalFiles}</div>
              <div className="text-xs md:text-sm text-muted-foreground">Archivos</div>
            </div>
            <div className="text-center space-y-1">
              <div className="text-xl md:text-2xl font-bold text-success">
                {stats.categories.length}
              </div>
              <div className="text-xs md:text-sm text-muted-foreground">Categorías</div>
            </div>
            <div className="text-center space-y-1">
              <div className="text-xl md:text-2xl font-bold text-warning">
                {formatFileSize(stats.totalSize)}
              </div>
              <div className="text-xs md:text-sm text-muted-foreground">Almacenado</div>
            </div>
          </div>

          {/* Controles de Búsqueda y Filtros */}
          <div className="space-y-3 md:space-y-4">
            {/* Búsqueda */}
            <div className="flex flex-col space-y-3 md:flex-row md:items-center md:gap-4 md:space-y-0">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
                <Input
                  type="text"
                  placeholder="Buscar por título, descripción, etiquetas..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 pr-4 h-11 text-base md:h-10 md:text-sm"
                />
              </div>
              <div className="flex gap-2 md:gap-3">
                <Button
                  variant={viewMode === "grid" ? "default" : "outline"}
                  size="sm"
                  className="h-11 md:h-10"
                  onClick={() => setViewMode("grid")}
                >
                  <Grid3X3 className="h-4 w-4" />
                </Button>
                <Button
                  variant={viewMode === "list" ? "default" : "outline"}
                  size="sm"
                  className="h-11 md:h-10"
                  onClick={() => setViewMode("list")}
                >
                  <List className="h-4 w-4" />
                </Button>
              </div>
            </div>

            {/* Filtros */}
            <div className="flex flex-col space-y-3 md:flex-row md:items-center md:gap-4 md:space-y-0">
              <div className="flex-1 grid grid-cols-1 md:grid-cols-3 gap-3">
                <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                  <SelectTrigger className="h-11 md:h-10">
                    <SelectValue placeholder="Todas las categorías" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todas las categorías</SelectItem>
                    {Object.entries(categoryConfig).map(([value, config]) => (
                      <SelectItem key={value} value={value}>
                        <div className="flex items-center gap-2">
                          <config.icon className="h-4 w-4" />
                          {config.label}
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                <Select value={selectedTruck} onValueChange={setSelectedTruck}>
                  <SelectTrigger className="h-11 md:h-10">
                    <SelectValue placeholder="Todos los camiones" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todos los camiones</SelectItem>
                    <SelectItem value="none">Sin asociar</SelectItem>
                    {trucks.map((truck) => (
                      <SelectItem key={truck.id} value={truck.id}>
                        {truck.licensePlate} - {truck.brand}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                <Select value={sortBy} onValueChange={setSortBy}>
                  <SelectTrigger className="h-11 md:h-10">
                    <SelectValue placeholder="Ordenar por" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="date-desc">Fecha (más reciente)</SelectItem>
                    <SelectItem value="date-asc">Fecha (más antiguo)</SelectItem>
                    <SelectItem value="name-asc">Nombre (A-Z)</SelectItem>
                    <SelectItem value="name-desc">Nombre (Z-A)</SelectItem>
                    <SelectItem value="size-desc">Tamaño (mayor)</SelectItem>
                    <SelectItem value="size-asc">Tamaño (menor)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>

          {/* Documentos */}
          {viewMode === "grid" ? (
            <div className="space-y-3 md:grid md:grid-cols-2 lg:grid-cols-3 md:gap-4 md:space-y-0">
              {sortedDocuments.map((document) => {
                const categoryConfig_item = categoryConfig[document.category as keyof typeof categoryConfig];
                const CategoryIcon = categoryConfig_item.icon;

                return (
                  <Card 
                    key={document.id} 
                    className="hover:shadow-lg transition-all duration-200 cursor-pointer hover-lift border-l-4 active:scale-[0.98] md:active:scale-100"
                    style={{ borderLeftColor: `var(--${categoryConfig_item.color.replace('bg-', 'color-')})` }}
                  >
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="flex-1 min-w-0">
                          <CardTitle className="text-base md:text-lg flex items-center gap-2 mb-1">
                            <CategoryIcon className="h-4 w-4 flex-shrink-0" />
                            <span className="truncate">{document.title}</span>
                          </CardTitle>
                          <CardDescription className="text-sm line-clamp-2">
                            {document.description}
                          </CardDescription>
                        </div>
                        
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm" className="h-8 w-8 p-0 ml-2">
                              <MoreVertical className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => handleViewDocument(document)}>
                              <Eye className="h-4 w-4 mr-2" />
                              Ver
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleDownloadDocument(document)}>
                              <Download className="h-4 w-4 mr-2" />
                              Descargar
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem 
                              onClick={() => handleDeleteDocument(document.id)}
                              className="text-destructive focus:text-destructive"
                            >
                              <Trash2 className="h-4 w-4 mr-2" />
                              Eliminar
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </div>
                    </CardHeader>

                    <CardContent className="space-y-3 pt-0">
                      {/* Información del camión si está asociado */}
                      {document.truckPlate && (
                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                          <Truck className="h-4 w-4 flex-shrink-0" />
                          <span className="truncate">{document.truckPlate}</span>
                        </div>
                      )}
                      
                      {/* Estadísticas del documento */}
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-muted-foreground">
                          {document.totalFiles} archivo{document.totalFiles > 1 ? 's' : ''}
                        </span>
                        <span className="font-medium">{formatFileSize(document.totalSize)}</span>
                      </div>

                      {/* Tags */}
                      {document.tags.length > 0 && (
                        <div className="flex flex-wrap gap-1">
                          {document.tags.slice(0, 3).map((tag) => (
                            <Badge key={tag} variant="secondary" className="text-xs">
                              {tag}
                            </Badge>
                          ))}
                          {document.tags.length > 3 && (
                            <Badge variant="outline" className="text-xs">
                              +{document.tags.length - 3}
                            </Badge>
                          )}
                        </div>
                      )}
                      
                      {/* Información temporal */}
                      <div className="pt-2 border-t space-y-1 text-xs text-muted-foreground">
                        <div className="flex items-center justify-between">
                          <span>Creado por:</span>
                          <span className="font-medium">{document.createdBy}</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span>Fecha:</span>
                          <span className="font-medium">{formatDate(document.createdAt)}</span>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}

              {/* Estado vacío */}
              {sortedDocuments.length === 0 && (
                <div className="col-span-full text-center py-8 md:py-12">
                  {searchTerm || selectedCategory !== "all" || selectedTruck !== "all" ? (
                    <>
                      <Search className="h-8 w-8 md:h-12 md:w-12 text-muted-foreground mx-auto mb-3 md:mb-4" />
                      <h3 className="font-medium text-base md:text-lg mb-2">No se encontraron documentos</h3>
                      <p className="text-sm md:text-base text-muted-foreground mb-3 md:mb-4">
                        Intenta con diferentes filtros o términos de búsqueda
                      </p>
                      <Button 
                        variant="outline"
                        onClick={() => {
                          setSearchTerm("");
                          setSelectedCategory("all");
                          setSelectedTruck("all");
                        }}
                        className="h-10 md:h-9"
                      >
                        Limpiar filtros
                      </Button>
                    </>
                  ) : (
                    <>
                      <FolderOpen className="h-8 w-8 md:h-12 md:w-12 text-muted-foreground mx-auto mb-3 md:mb-4" />
                      <h3 className="font-medium text-base md:text-lg mb-2">No hay documentos</h3>
                      <p className="text-sm md:text-base text-muted-foreground mb-3 md:mb-4">
                        Comienza subiendo el primer documento de tu flota.
                      </p>
                      <Button 
                        onClick={() => setIsUploadModalOpen(true)}
                        className="gradient-primary h-11 md:h-10"
                      >
                        <Plus className="h-4 w-4 mr-2" />
                        Subir Primer Documento
                      </Button>
                    </>
                  )}
                </div>
              )}
            </div>
          ) : (
            // Vista de lista (implementación básica para este ejemplo)
            <div className="space-y-2">
              {sortedDocuments.map((document) => {
                const categoryConfig_item = categoryConfig[document.category as keyof typeof categoryConfig];
                const CategoryIcon = categoryConfig_item.icon;

                return (
                  <Card key={document.id} className="hover:shadow-md transition-all duration-200">
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4 flex-1 min-w-0">
                          <CategoryIcon className="h-5 w-5 text-muted-foreground flex-shrink-0" />
                          <div className="min-w-0 flex-1">
                            <h4 className="font-medium text-sm truncate">{document.title}</h4>
                            <p className="text-xs text-muted-foreground truncate">{document.description}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-4 flex-shrink-0">
                          <div className="text-xs text-muted-foreground text-right hidden md:block">
                            <div>{document.totalFiles} archivos</div>
                            <div>{formatFileSize(document.totalSize)}</div>
                          </div>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                                <MoreVertical className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => handleViewDocument(document)}>
                                <Eye className="h-4 w-4 mr-2" />
                                Ver
                              </DropdownMenuItem>
                              <DropdownMenuItem onClick={() => handleDownloadDocument(document)}>
                                <Download className="h-4 w-4 mr-2" />
                                Descargar
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem 
                                onClick={() => handleDeleteDocument(document.id)}
                                className="text-destructive focus:text-destructive"
                              >
                                <Trash2 className="h-4 w-4 mr-2" />
                                Eliminar
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Modal de Subida */}
      <UploadDocumentModal
        isOpen={isUploadModalOpen}
        onClose={() => setIsUploadModalOpen(false)}
        onSave={handleDocumentSave}
        trucks={trucks}
      />

      {/* Modal de Vista Previa */}
      <DocumentPreviewModal
        isOpen={isPreviewModalOpen}
        onClose={() => setIsPreviewModalOpen(false)}
        document={selectedDocument}
      />
    </div>
  );
}