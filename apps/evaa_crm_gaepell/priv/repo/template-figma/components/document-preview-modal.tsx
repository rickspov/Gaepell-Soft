import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "./ui/dialog";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Card, CardContent } from "./ui/card";
import { ScrollArea } from "./ui/scroll-area";
import { Separator } from "./ui/separator";
import { toast } from "sonner@2.0.3";
import { 
  X,
  Download,
  Share2,
  Truck,
  User,
  Calendar,
  FileText,
  Image,
  Eye,
  ZoomIn,
  ZoomOut,
  RotateCw,
  Maximize
} from "lucide-react";

interface DocumentPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  document: any;
}

// Componente para previsualizar imágenes
const ImagePreview = ({ file }: { file: any }) => {
  const [scale, setScale] = useState(1);
  const [rotation, setRotation] = useState(0);

  const handleZoomIn = () => setScale(prev => Math.min(prev + 0.25, 3));
  const handleZoomOut = () => setScale(prev => Math.max(prev - 0.25, 0.25));
  const handleRotate = () => setRotation(prev => (prev + 90) % 360);
  const handleReset = () => {
    setScale(1);
    setRotation(0);
  };

  return (
    <div className="relative h-full">
      {/* Controles de imagen */}
      <div className="absolute top-2 right-2 z-10 flex gap-2">
        <Button variant="secondary" size="sm" onClick={handleZoomOut} disabled={scale <= 0.25}>
          <ZoomOut className="h-4 w-4" />
        </Button>
        <Button variant="secondary" size="sm" onClick={handleZoomIn} disabled={scale >= 3}>
          <ZoomIn className="h-4 w-4" />
        </Button>
        <Button variant="secondary" size="sm" onClick={handleRotate}>
          <RotateCw className="h-4 w-4" />
        </Button>
        <Button variant="secondary" size="sm" onClick={handleReset}>
          <Maximize className="h-4 w-4" />
        </Button>
      </div>

      {/* Imagen */}
      <div className="h-full overflow-auto bg-muted/50 rounded-lg p-4">
        <div className="flex items-center justify-center min-h-full">
          <img
            src={file.url}
            alt={file.name}
            className="max-w-full max-h-full object-contain transition-transform duration-200"
            style={{
              transform: `scale(${scale}) rotate(${rotation}deg)`
            }}
          />
        </div>
      </div>

      {/* Información de la imagen */}
      <div className="absolute bottom-2 left-2 bg-black/80 text-white text-xs px-2 py-1 rounded">
        {Math.round(scale * 100)}% • {file.name}
      </div>
    </div>
  );
};

// Componente para previsualizar PDFs (simulado)
const PDFPreview = ({ file }: { file: any }) => {
  return (
    <div className="h-full bg-muted/50 rounded-lg p-4 flex items-center justify-center">
      <div className="text-center">
        <FileText className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
        <h3 className="font-medium text-lg mb-2">Vista previa de PDF</h3>
        <p className="text-sm text-muted-foreground mb-4">
          {file.name}
        </p>
        <Button variant="outline" onClick={() => window.open(file.url, '_blank')}>
          <Eye className="h-4 w-4 mr-2" />
          Abrir en nueva ventana
        </Button>
      </div>
    </div>
  );
};

// Función para formatear fechas
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('es-ES', {
    day: '2-digit',
    month: 'long',
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

export function DocumentPreviewModal({ isOpen, onClose, document }: DocumentPreviewModalProps) {
  const [selectedFileIndex, setSelectedFileIndex] = useState(0);

  if (!document) return null;

  const selectedFile = document.files[selectedFileIndex];

  const handleDownload = () => {
    // Simular descarga
    toast.success("Descarga iniciada", {
      description: `Descargando "${selectedFile.name}".`
    });
  };

  const handleShare = () => {
    // Simular compartir
    toast.success("Enlace copiado", {
      description: "El enlace del documento ha sido copiado al portapapeles."
    });
  };

  const renderPreview = () => {
    switch (selectedFile.type) {
      case 'image':
        return <ImagePreview file={selectedFile} />;
      case 'pdf':
        return <PDFPreview file={selectedFile} />;
      default:
        return (
          <div className="h-full bg-muted/50 rounded-lg p-4 flex items-center justify-center">
            <div className="text-center">
              <FileText className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
              <h3 className="font-medium text-lg mb-2">Archivo no previsualizable</h3>
              <p className="text-sm text-muted-foreground mb-4">
                {selectedFile.name}
              </p>
              <Button variant="outline" onClick={handleDownload}>
                <Download className="h-4 w-4 mr-2" />
                Descargar archivo
              </Button>
            </div>
          </div>
        );
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-full h-full md:max-w-6xl md:h-[95vh] p-0 gap-0 mobile-modal">
        <div className="flex flex-col h-full">
          {/* Header */}
          <DialogHeader className="p-4 md:p-6 border-b bg-background/80 backdrop-blur-sm">
            <div className="flex items-center justify-between">
              <div className="min-w-0 flex-1">
                <DialogTitle className="text-lg md:text-xl truncate">
                  {document.title}
                </DialogTitle>
                <DialogDescription className="text-sm truncate">
                  {document.description}
                </DialogDescription>
              </div>
              <div className="flex items-center gap-2 ml-4">
                <Button variant="outline" size="sm" onClick={handleShare}>
                  <Share2 className="h-4 w-4 mr-2 md:mr-0 md:h-4 md:w-4" />
                  <span className="md:hidden">Compartir</span>
                </Button>
                <Button variant="outline" size="sm" onClick={handleDownload}>
                  <Download className="h-4 w-4 mr-2 md:mr-0 md:h-4 md:w-4" />
                  <span className="md:hidden">Descargar</span>
                </Button>
                <Button variant="ghost" size="sm" onClick={onClose}>
                  <X className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </DialogHeader>

          <div className="flex flex-1 overflow-hidden">
            {/* Panel de información lateral - Solo visible en desktop */}
            <div className="hidden md:block w-80 border-r bg-muted/20">
              <ScrollArea className="h-full">
                <div className="p-4 space-y-4">
                  {/* Información del documento */}
                  <div className="space-y-3">
                    <h4 className="font-medium">Información del Documento</h4>
                    
                    <div className="space-y-2 text-sm">
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4 text-muted-foreground" />
                        <span className="text-muted-foreground">Creado:</span>
                        <span className="font-medium">{formatDate(document.createdAt)}</span>
                      </div>
                      
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4 text-muted-foreground" />
                        <span className="text-muted-foreground">Por:</span>
                        <span className="font-medium">{document.createdBy}</span>
                      </div>

                      {document.truckPlate && (
                        <div className="flex items-center gap-2">
                          <Truck className="h-4 w-4 text-muted-foreground" />
                          <span className="text-muted-foreground">Camión:</span>
                          <span className="font-medium">{document.truckPlate}</span>
                        </div>
                      )}
                    </div>

                    {/* Tags */}
                    {document.tags.length > 0 && (
                      <div className="space-y-2">
                        <h5 className="font-medium text-sm">Etiquetas</h5>
                        <div className="flex flex-wrap gap-1">
                          {document.tags.map((tag: string) => (
                            <Badge key={tag} variant="secondary" className="text-xs">
                              {tag}
                            </Badge>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>

                  <Separator />

                  {/* Lista de archivos */}
                  <div className="space-y-3">
                    <h4 className="font-medium">
                      Archivos ({document.files.length})
                    </h4>
                    
                    <div className="space-y-2">
                      {document.files.map((file: any, index: number) => (
                        <Card
                          key={file.id}
                          className={`cursor-pointer transition-colors ${
                            selectedFileIndex === index 
                              ? 'border-primary bg-primary/5' 
                              : 'hover:bg-muted/50'
                          }`}
                          onClick={() => setSelectedFileIndex(index)}
                        >
                          <CardContent className="p-3">
                            <div className="flex items-center gap-2">
                              {file.type === 'image' ? (
                                <Image className="h-4 w-4 text-muted-foreground" />
                              ) : (
                                <FileText className="h-4 w-4 text-muted-foreground" />
                              )}
                              <div className="min-w-0 flex-1">
                                <p className="font-medium text-sm truncate">{file.name}</p>
                                <p className="text-xs text-muted-foreground">
                                  {formatFileSize(file.size)}
                                </p>
                              </div>
                            </div>
                          </CardContent>
                        </Card>
                      ))}
                    </div>
                  </div>
                </div>
              </ScrollArea>
            </div>

            {/* Área de previsualización principal */}
            <div className="flex-1 p-4 md:p-6">
              <div className="h-full">
                {/* Selector de archivos para móvil */}
                <div className="md:hidden mb-4">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-medium">
                      Archivo {selectedFileIndex + 1} de {document.files.length}
                    </h4>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={selectedFileIndex === 0}
                        onClick={() => setSelectedFileIndex(prev => prev - 1)}
                      >
                        ←
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={selectedFileIndex === document.files.length - 1}
                        onClick={() => setSelectedFileIndex(prev => prev + 1)}
                      >
                        →
                      </Button>
                    </div>
                  </div>
                  <p className="text-sm text-muted-foreground truncate">
                    {selectedFile.name} • {formatFileSize(selectedFile.size)}
                  </p>
                </div>

                {/* Previsualización */}
                {renderPreview()}
              </div>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}