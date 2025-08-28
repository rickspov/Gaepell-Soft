import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Textarea } from "./ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { RadioGroup, RadioGroupItem } from "./ui/radio-group";
import { Checkbox } from "./ui/checkbox";
import { Progress } from "./ui/progress";
import { Badge } from "./ui/badge";
import { 
  ChevronLeft,
  ChevronRight,
  Upload,
  X,
  Check,
  AlertTriangle,
  Truck,
  FileText
} from "lucide-react";

interface TicketWizardProps {
  onComplete?: (ticketData: any) => void;
  onCancel?: () => void;
}

const steps = [
  { id: 1, title: "Información Básica", description: "Datos generales del ticket" },
  { id: 2, title: "Detalles del Problema", description: "Descripción y tipo de problema" },
  { id: 3, title: "Documentación", description: "Fotos y archivos adjuntos" },
  { id: 4, title: "Prioridad y Asignación", description: "Configuración final" },
  { id: 5, title: "Confirmación", description: "Revisar y confirmar" }
];

const trucks = [
  { id: "TRK-001", plate: "ABC-123", model: "Volvo FH 460" },
  { id: "TRK-002", plate: "DEF-456", model: "Mercedes Actros 1845" },
  { id: "TRK-003", plate: "GHI-789", model: "Scania R 450" }
];

const problemTypes = [
  { id: "mechanical", label: "Mecánico", description: "Problemas del motor, transmisión, etc." },
  { id: "electrical", label: "Eléctrico", description: "Sistema eléctrico, luces, etc." },
  { id: "bodywork", label: "Carrocería", description: "Daños externos, pintura, etc." },
  { id: "preventive", label: "Mantenimiento Preventivo", description: "Mantenimiento programado" },
  { id: "inspection", label: "Inspección", description: "Revisión técnica o inspección" }
];

const technicians = [
  { id: "TECH-001", name: "Carlos García", speciality: "Mecánica General" },
  { id: "TECH-002", name: "María López", speciality: "Sistema Eléctrico" },
  { id: "TECH-003", name: "Luis Rodríguez", speciality: "Carrocería" }
];

export function TicketWizard({ onComplete, onCancel }: TicketWizardProps) {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState({
    // Step 1
    truckId: "",
    reportedBy: "",
    location: "",
    // Step 2
    problemType: "",
    title: "",
    description: "",
    symptoms: [] as string[],
    // Step 3
    photos: [] as File[],
    documents: [] as File[],
    // Step 4
    priority: "",
    assignedTo: "",
    estimatedTime: "",
    // Step 5 - Confirmation
  });

  const progress = (currentStep / steps.length) * 100;

  const handleNext = () => {
    if (currentStep < steps.length) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleComplete = () => {
    onComplete?.(formData);
  };

  const updateFormData = (updates: Partial<typeof formData>) => {
    setFormData({ ...formData, ...updates });
  };

  const handleFileUpload = (files: FileList | null, type: 'photos' | 'documents') => {
    if (files) {
      const newFiles = Array.from(files);
      updateFormData({
        [type]: [...formData[type], ...newFiles]
      });
    }
  };

  const removeFile = (index: number, type: 'photos' | 'documents') => {
    const newFiles = [...formData[type]];
    newFiles.splice(index, 1);
    updateFormData({ [type]: newFiles });
  };

  const renderStep = () => {
    switch (currentStep) {
      case 1:
        return (
          <div className="space-y-6">
            <div>
              <Label htmlFor="truck">Camión *</Label>
              <Select value={formData.truckId} onValueChange={(value) => updateFormData({ truckId: value })}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecciona un camión" />
                </SelectTrigger>
                <SelectContent>
                  {trucks.map((truck) => (
                    <SelectItem key={truck.id} value={truck.id}>
                      {truck.plate} - {truck.model}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="reportedBy">Reportado por *</Label>
              <Input
                id="reportedBy"
                value={formData.reportedBy}
                onChange={(e) => updateFormData({ reportedBy: e.target.value })}
                placeholder="Nombre del reportante"
              />
            </div>

            <div>
              <Label htmlFor="location">Ubicación</Label>
              <Input
                id="location"
                value={formData.location}
                onChange={(e) => updateFormData({ location: e.target.value })}
                placeholder="Ubicación donde se encuentra el camión"
              />
            </div>
          </div>
        );

      case 2:
        return (
          <div className="space-y-6">
            <div>
              <Label>Tipo de Problema *</Label>
              <RadioGroup 
                value={formData.problemType} 
                onValueChange={(value) => updateFormData({ problemType: value })}
                className="mt-3"
              >
                {problemTypes.map((type) => (
                  <div key={type.id} className="flex items-start space-x-3 p-3 border rounded-lg">
                    <RadioGroupItem value={type.id} id={type.id} className="mt-1" />
                    <div className="flex-1">
                      <Label htmlFor={type.id} className="font-medium cursor-pointer">
                        {type.label}
                      </Label>
                      <p className="text-sm text-muted-foreground">{type.description}</p>
                    </div>
                  </div>
                ))}
              </RadioGroup>
            </div>

            <div>
              <Label htmlFor="title">Título del Problema *</Label>
              <Input
                id="title"
                value={formData.title}
                onChange={(e) => updateFormData({ title: e.target.value })}
                placeholder="Describe brevemente el problema"
              />
            </div>

            <div>
              <Label htmlFor="description">Descripción Detallada *</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => updateFormData({ description: e.target.value })}
                placeholder="Describe en detalle el problema, síntomas observados, condiciones en las que ocurre, etc."
                rows={4}
              />
            </div>

            <div>
              <Label>Síntomas Observados</Label>
              <div className="mt-3 space-y-2">
                {["Ruidos extraños", "Vibración", "Pérdida de potencia", "Fugas", "Luces de advertencia", "Otros"].map((symptom) => (
                  <div key={symptom} className="flex items-center space-x-2">
                    <Checkbox
                      id={symptom}
                      checked={formData.symptoms.includes(symptom)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          updateFormData({ symptoms: [...formData.symptoms, symptom] });
                        } else {
                          updateFormData({ symptoms: formData.symptoms.filter(s => s !== symptom) });
                        }
                      }}
                    />
                    <Label htmlFor={symptom} className="cursor-pointer">{symptom}</Label>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );

      case 3:
        return (
          <div className="space-y-6">
            <div>
              <Label>Fotos del Problema</Label>
              <div className="mt-3">
                <div className="border-2 border-dashed border-muted-foreground/25 rounded-lg p-6 text-center">
                  <Upload className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-sm text-muted-foreground mb-2">
                    Arrastra fotos aquí o haz clic para seleccionar
                  </p>
                  <input
                    type="file"
                    multiple
                    accept="image/*"
                    className="hidden"
                    id="photo-upload"
                    onChange={(e) => handleFileUpload(e.target.files, 'photos')}
                  />
                  <Label htmlFor="photo-upload" className="cursor-pointer">
                    <Button variant="outline" className="pointer-events-none">
                      Seleccionar Fotos
                    </Button>
                  </Label>
                </div>

                {formData.photos.length > 0 && (
                  <div className="mt-4">
                    <p className="text-sm font-medium mb-2">Fotos seleccionadas:</p>
                    <div className="space-y-2">
                      {formData.photos.map((file, index) => (
                        <div key={index} className="flex items-center justify-between p-2 border rounded">
                          <span className="text-sm">{file.name}</span>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => removeFile(index, 'photos')}
                          >
                            <X className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div>
              <Label>Documentos Adicionales</Label>
              <div className="mt-3">
                <div className="border-2 border-dashed border-muted-foreground/25 rounded-lg p-6 text-center">
                  <FileText className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-sm text-muted-foreground mb-2">
                    Sube documentos relevantes (PDF, DOC, etc.)
                  </p>
                  <input
                    type="file"
                    multiple
                    accept=".pdf,.doc,.docx,.txt"
                    className="hidden"
                    id="document-upload"
                    onChange={(e) => handleFileUpload(e.target.files, 'documents')}
                  />
                  <Label htmlFor="document-upload" className="cursor-pointer">
                    <Button variant="outline" className="pointer-events-none">
                      Seleccionar Documentos
                    </Button>
                  </Label>
                </div>

                {formData.documents.length > 0 && (
                  <div className="mt-4">
                    <p className="text-sm font-medium mb-2">Documentos seleccionados:</p>
                    <div className="space-y-2">
                      {formData.documents.map((file, index) => (
                        <div key={index} className="flex items-center justify-between p-2 border rounded">
                          <span className="text-sm">{file.name}</span>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => removeFile(index, 'documents')}
                          >
                            <X className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        );

      case 4:
        return (
          <div className="space-y-6">
            <div>
              <Label>Prioridad *</Label>
              <RadioGroup 
                value={formData.priority} 
                onValueChange={(value) => updateFormData({ priority: value })}
                className="mt-3"
              >
                <div className="flex items-center space-x-3 p-3 border rounded-lg">
                  <RadioGroupItem value="low" id="low" />
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-success"></div>
                    <Label htmlFor="low" className="cursor-pointer">Baja - Puede esperar</Label>
                  </div>
                </div>
                <div className="flex items-center space-x-3 p-3 border rounded-lg">
                  <RadioGroupItem value="medium" id="medium" />
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-warning"></div>
                    <Label htmlFor="medium" className="cursor-pointer">Media - Atender pronto</Label>
                  </div>
                </div>
                <div className="flex items-center space-x-3 p-3 border rounded-lg">
                  <RadioGroupItem value="high" id="high" />
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-destructive"></div>
                    <Label htmlFor="high" className="cursor-pointer">Alta - Urgente</Label>
                  </div>
                </div>
              </RadioGroup>
            </div>

            <div>
              <Label htmlFor="assignedTo">Asignar a Técnico</Label>
              <Select value={formData.assignedTo} onValueChange={(value) => updateFormData({ assignedTo: value })}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecciona un técnico" />
                </SelectTrigger>
                <SelectContent>
                  {technicians.map((tech) => (
                    <SelectItem key={tech.id} value={tech.id}>
                      {tech.name} - {tech.speciality}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="estimatedTime">Tiempo Estimado</Label>
              <Select value={formData.estimatedTime} onValueChange={(value) => updateFormData({ estimatedTime: value })}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecciona tiempo estimado" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1-2h">1-2 horas</SelectItem>
                  <SelectItem value="half-day">Medio día</SelectItem>
                  <SelectItem value="full-day">Día completo</SelectItem>
                  <SelectItem value="2-3-days">2-3 días</SelectItem>
                  <SelectItem value="1-week">1 semana</SelectItem>
                  <SelectItem value="custom">Personalizado</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        );

      case 5:
        const selectedTruck = trucks.find(t => t.id === formData.truckId);
        const selectedProblemType = problemTypes.find(p => p.id === formData.problemType);
        const selectedTechnician = technicians.find(t => t.id === formData.assignedTo);

        return (
          <div className="space-y-6">
            <div className="text-center">
              <Check className="h-12 w-12 text-success mx-auto mb-4" />
              <h3 className="text-lg font-semibold">Revisar Información del Ticket</h3>
              <p className="text-muted-foreground">Verifica que todos los datos sean correctos antes de crear el ticket</p>
            </div>

            <div className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Información Básica</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span>Camión:</span>
                    <span className="font-medium">{selectedTruck?.plate} - {selectedTruck?.model}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Reportado por:</span>
                    <span className="font-medium">{formData.reportedBy}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Ubicación:</span>
                    <span className="font-medium">{formData.location || "No especificada"}</span>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Detalles del Problema</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span>Tipo:</span>
                    <span className="font-medium">{selectedProblemType?.label}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Título:</span>
                    <span className="font-medium">{formData.title}</span>
                  </div>
                  <div>
                    <span>Descripción:</span>
                    <p className="font-medium mt-1">{formData.description}</p>
                  </div>
                  {formData.symptoms.length > 0 && (
                    <div>
                      <span>Síntomas:</span>
                      <div className="flex flex-wrap gap-1 mt-1">
                        {formData.symptoms.map((symptom) => (
                          <Badge key={symptom} variant="secondary" className="text-xs">
                            {symptom}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Configuración</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span>Prioridad:</span>
                    <Badge 
                      className={
                        formData.priority === 'high' ? 'bg-destructive text-destructive-foreground' :
                        formData.priority === 'medium' ? 'bg-warning text-warning-foreground' :
                        'bg-success text-success-foreground'
                      }
                    >
                      {formData.priority === 'high' ? 'Alta' : formData.priority === 'medium' ? 'Media' : 'Baja'}
                    </Badge>
                  </div>
                  <div className="flex justify-between">
                    <span>Asignado a:</span>
                    <span className="font-medium">{selectedTechnician?.name || "Sin asignar"}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Tiempo estimado:</span>
                    <span className="font-medium">{formData.estimatedTime || "Sin estimar"}</span>
                  </div>
                </CardContent>
              </Card>

              {(formData.photos.length > 0 || formData.documents.length > 0) && (
                <Card>
                  <CardHeader>
                    <CardTitle className="text-base">Archivos Adjuntos</CardTitle>
                  </CardHeader>
                  <CardContent className="text-sm">
                    <div className="flex justify-between">
                      <span>Fotos:</span>
                      <span className="font-medium">{formData.photos.length}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Documentos:</span>
                      <span className="font-medium">{formData.documents.length}</span>
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-2xl font-bold">Crear Nuevo Ticket de Mantenimiento</h1>
        <p className="text-muted-foreground">Complete la información paso a paso</p>
      </div>

      {/* Progress */}
      <div className="space-y-2">
        <div className="flex justify-between text-sm">
          <span>Paso {currentStep} de {steps.length}</span>
          <span>{Math.round(progress)}% completado</span>
        </div>
        <Progress value={progress} className="h-2" />
      </div>

      {/* Steps Navigation */}
      <div className="flex justify-between">
        {steps.map((step, index) => (
          <div 
            key={step.id} 
            className={`flex-1 text-center ${index < steps.length - 1 ? 'border-r' : ''}`}
          >
            <div className={`inline-flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium mb-2 ${
              currentStep >= step.id 
                ? 'bg-primary text-primary-foreground' 
                : 'bg-muted text-muted-foreground'
            }`}>
              {currentStep > step.id ? <Check className="h-4 w-4" /> : step.id}
            </div>
            <div className="text-xs">
              <p className="font-medium">{step.title}</p>
              <p className="text-muted-foreground">{step.description}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Step Content */}
      <Card>
        <CardHeader>
          <CardTitle>{steps[currentStep - 1]?.title}</CardTitle>
          <CardDescription>{steps[currentStep - 1]?.description}</CardDescription>
        </CardHeader>
        <CardContent>
          {renderStep()}
        </CardContent>
      </Card>

      {/* Navigation Buttons */}
      <div className="flex justify-between">
        <div className="flex gap-2">
          <Button variant="outline" onClick={onCancel}>
            Cancelar
          </Button>
          {currentStep > 1 && (
            <Button variant="outline" onClick={handlePrevious}>
              <ChevronLeft className="h-4 w-4 mr-2" />
              Anterior
            </Button>
          )}
        </div>
        
        <div>
          {currentStep < steps.length ? (
            <Button onClick={handleNext}>
              Siguiente
              <ChevronRight className="h-4 w-4 ml-2" />
            </Button>
          ) : (
            <Button onClick={handleComplete}>
              Crear Ticket
              <Check className="h-4 w-4 ml-2" />
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}