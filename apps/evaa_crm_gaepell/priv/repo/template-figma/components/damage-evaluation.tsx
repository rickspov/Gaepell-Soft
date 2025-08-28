import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Textarea } from "./ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { RadioGroup, RadioGroupItem } from "./ui/radio-group";
import { Checkbox } from "./ui/checkbox";
import { Badge } from "./ui/badge";
import { Separator } from "./ui/separator";
import { 
  Camera,
  Upload,
  X,
  Save,
  Send,
  AlertTriangle,
  CheckCircle,
  FileText,
  MapPin
} from "lucide-react";

interface DamageEvaluationProps {
  truckId?: string;
  onSave?: (evaluationData: any) => void;
  onSubmit?: (evaluationData: any) => void;
}

const evaluationTypes = [
  { id: "collision", label: "Colisión", description: "Daños por accidente o choque" },
  { id: "wear", label: "Desgaste", description: "Desgaste normal por uso" },
  { id: "vandalism", label: "Vandalismo", description: "Daños intencionales" },
  { id: "weather", label: "Clima", description: "Daños por condiciones climáticas" },
  { id: "mechanical", label: "Mecánico", description: "Fallas mecánicas o estructurales" }
];

const damageAreas = [
  "Frontal", "Lateral Izquierdo", "Lateral Derecho", "Trasero", 
  "Techo", "Cabina", "Caja/Remolque", "Llantas", "Motor", "Interior"
];

const severityLevels = [
  { id: "minor", label: "Menor", description: "Daño cosmético, no afecta funcionamiento", color: "success" },
  { id: "moderate", label: "Moderado", description: "Requiere reparación, afecta parcialmente", color: "warning" },
  { id: "severe", label: "Severo", description: "Daño crítico, requiere atención inmediata", color: "destructive" }
];

const trucks = [
  { id: "TRK-001", plate: "ABC-123", model: "Volvo FH 460" },
  { id: "TRK-002", plate: "DEF-456", model: "Mercedes Actros 1845" },
  { id: "TRK-003", plate: "GHI-789", model: "Scania R 450" }
];

export function DamageEvaluation({ truckId, onSave, onSubmit }: DamageEvaluationProps) {
  const [formData, setFormData] = useState({
    truckId: truckId || "",
    evaluationType: "",
    evaluatedBy: "",
    location: "",
    incidentDate: "",
    reportDate: new Date().toISOString().split('T')[0],
    description: "",
    damageAreas: [] as string[],
    severity: "",
    estimatedCost: "",
    isVehicleOperable: "",
    requiresTowing: false,
    immediateAction: "",
    photos: [] as File[],
    notes: ""
  });

  const updateFormData = (updates: Partial<typeof formData>) => {
    setFormData({ ...formData, ...updates });
  };

  const handleAreaToggle = (area: string) => {
    const newAreas = formData.damageAreas.includes(area)
      ? formData.damageAreas.filter(a => a !== area)
      : [...formData.damageAreas, area];
    updateFormData({ damageAreas: newAreas });
  };

  const handleFileUpload = (files: FileList | null) => {
    if (files) {
      const newFiles = Array.from(files);
      updateFormData({ photos: [...formData.photos, ...newFiles] });
    }
  };

  const removePhoto = (index: number) => {
    const newPhotos = [...formData.photos];
    newPhotos.splice(index, 1);
    updateFormData({ photos: newPhotos });
  };

  const handleSave = () => {
    onSave?.(formData);
  };

  const handleSubmit = () => {
    onSubmit?.(formData);
  };

  const getSeverityColor = (severity: string) => {
    const level = severityLevels.find(s => s.id === severity);
    return level?.color || "secondary";
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-2xl font-bold">Evaluación de Daños</h1>
        <p className="text-muted-foreground">Documenta y evalúa los daños del vehículo</p>
      </div>

      {/* Basic Information */}
      <Card>
        <CardHeader>
          <CardTitle>Información Básica</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
              <Label htmlFor="evaluatedBy">Evaluado por *</Label>
              <Input
                id="evaluatedBy"
                value={formData.evaluatedBy}
                onChange={(e) => updateFormData({ evaluatedBy: e.target.value })}
                placeholder="Nombre del evaluador"
              />
            </div>

            <div>
              <Label htmlFor="location">Ubicación del Incidente</Label>
              <Input
                id="location"
                value={formData.location}
                onChange={(e) => updateFormData({ location: e.target.value })}
                placeholder="Dirección o ubicación"
              />
            </div>

            <div>
              <Label htmlFor="incidentDate">Fecha del Incidente</Label>
              <Input
                id="incidentDate"
                type="date"
                value={formData.incidentDate}
                onChange={(e) => updateFormData({ incidentDate: e.target.value })}
              />
            </div>

            <div>
              <Label htmlFor="reportDate">Fecha del Reporte</Label>
              <Input
                id="reportDate"
                type="date"
                value={formData.reportDate}
                onChange={(e) => updateFormData({ reportDate: e.target.value })}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Evaluation Type */}
      <Card>
        <CardHeader>
          <CardTitle>Tipo de Evaluación</CardTitle>
        </CardHeader>
        <CardContent>
          <RadioGroup 
            value={formData.evaluationType} 
            onValueChange={(value) => updateFormData({ evaluationType: value })}
          >
            {evaluationTypes.map((type) => (
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
        </CardContent>
      </Card>

      {/* Damage Details */}
      <Card>
        <CardHeader>
          <CardTitle>Detalles del Daño</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <Label htmlFor="description">Descripción del Daño *</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => updateFormData({ description: e.target.value })}
              placeholder="Describe detalladamente los daños observados..."
              rows={4}
            />
          </div>

          <div>
            <Label>Áreas Afectadas</Label>
            <div className="mt-3 grid grid-cols-2 md:grid-cols-3 gap-3">
              {damageAreas.map((area) => (
                <div key={area} className="flex items-center space-x-2">
                  <Checkbox
                    id={area}
                    checked={formData.damageAreas.includes(area)}
                    onCheckedChange={() => handleAreaToggle(area)}
                  />
                  <Label htmlFor={area} className="cursor-pointer text-sm">{area}</Label>
                </div>
              ))}
            </div>
            {formData.damageAreas.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-2">
                {formData.damageAreas.map((area) => (
                  <Badge key={area} variant="secondary">
                    {area}
                  </Badge>
                ))}
              </div>
            )}
          </div>

          <div>
            <Label>Nivel de Severidad *</Label>
            <RadioGroup 
              value={formData.severity} 
              onValueChange={(value) => updateFormData({ severity: value })}
              className="mt-3"
            >
              {severityLevels.map((level) => (
                <div key={level.id} className="flex items-start space-x-3 p-3 border rounded-lg">
                  <RadioGroupItem value={level.id} id={level.id} className="mt-1" />
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <Label htmlFor={level.id} className="font-medium cursor-pointer">
                        {level.label}
                      </Label>
                      <div className={`w-3 h-3 rounded-full ${
                        level.color === 'success' ? 'bg-success' :
                        level.color === 'warning' ? 'bg-warning' :
                        'bg-destructive'
                      }`}></div>
                    </div>
                    <p className="text-sm text-muted-foreground">{level.description}</p>
                  </div>
                </div>
              ))}
            </RadioGroup>
          </div>

          <div>
            <Label htmlFor="estimatedCost">Costo Estimado de Reparación</Label>
            <Input
              id="estimatedCost"
              type="number"
              value={formData.estimatedCost}
              onChange={(e) => updateFormData({ estimatedCost: e.target.value })}
              placeholder="0.00"
              className="mt-1"
            />
          </div>
        </CardContent>
      </Card>

      {/* Vehicle Status */}
      <Card>
        <CardHeader>
          <CardTitle>Estado del Vehículo</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <Label>¿El vehículo es operable? *</Label>
            <RadioGroup 
              value={formData.isVehicleOperable} 
              onValueChange={(value) => updateFormData({ isVehicleOperable: value })}
              className="mt-3"
            >
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="yes" id="operable-yes" />
                <Label htmlFor="operable-yes" className="cursor-pointer">
                  Sí, puede moverse por sus propios medios
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="limited" id="operable-limited" />
                <Label htmlFor="operable-limited" className="cursor-pointer">
                  Parcialmente, con limitaciones
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="no" id="operable-no" />
                <Label htmlFor="operable-no" className="cursor-pointer">
                  No, requiere asistencia
                </Label>
              </div>
            </RadioGroup>
          </div>

          <div className="flex items-center space-x-2">
            <Checkbox
              id="requiresTowing"
              checked={formData.requiresTowing}
              onCheckedChange={(checked) => updateFormData({ requiresTowing: !!checked })}
            />
            <Label htmlFor="requiresTowing" className="cursor-pointer">
              Requiere grúa o remolque
            </Label>
          </div>

          <div>
            <Label htmlFor="immediateAction">Acción Inmediata Requerida</Label>
            <Textarea
              id="immediateAction"
              value={formData.immediateAction}
              onChange={(e) => updateFormData({ immediateAction: e.target.value })}
              placeholder="Describe las acciones inmediatas necesarias..."
              rows={3}
            />
          </div>
        </CardContent>
      </Card>

      {/* Photos */}
      <Card>
        <CardHeader>
          <CardTitle>Documentación Fotográfica</CardTitle>
          <CardDescription>Sube fotos que documenten los daños</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="border-2 border-dashed border-muted-foreground/25 rounded-lg p-6 text-center">
              <Camera className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
              <p className="text-sm text-muted-foreground mb-2">
                Arrastra fotos aquí o haz clic para seleccionar
              </p>
              <input
                type="file"
                multiple
                accept="image/*"
                className="hidden"
                id="photo-upload"
                onChange={(e) => handleFileUpload(e.target.files)}
              />
              <Label htmlFor="photo-upload" className="cursor-pointer">
                <Button variant="outline" className="pointer-events-none">
                  <Upload className="h-4 w-4 mr-2" />
                  Seleccionar Fotos
                </Button>
              </Label>
            </div>

            {formData.photos.length > 0 && (
              <div>
                <p className="text-sm font-medium mb-3">Fotos adjuntadas ({formData.photos.length}):</p>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {formData.photos.map((file, index) => (
                    <div key={index} className="relative">
                      <div className="aspect-square bg-muted rounded-lg border p-2 flex items-center justify-center">
                        <FileText className="h-8 w-8 text-muted-foreground" />
                      </div>
                      <p className="text-xs mt-1 truncate">{file.name}</p>
                      <Button
                        variant="destructive"
                        size="sm"
                        className="absolute -top-2 -right-2 h-6 w-6 rounded-full p-0"
                        onClick={() => removePhoto(index)}
                      >
                        <X className="h-3 w-3" />
                      </Button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Notes */}
      <Card>
        <CardHeader>
          <CardTitle>Notas Adicionales</CardTitle>
        </CardHeader>
        <CardContent>
          <Textarea
            value={formData.notes}
            onChange={(e) => updateFormData({ notes: e.target.value })}
            placeholder="Cualquier información adicional relevante..."
            rows={4}
          />
        </CardContent>
      </Card>

      {/* Summary */}
      {(formData.severity || formData.damageAreas.length > 0) && (
        <Card>
          <CardHeader>
            <CardTitle>Resumen de Evaluación</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {formData.severity && (
                <div className="flex items-center gap-2">
                  <span className="text-sm">Severidad:</span>
                  <Badge className={
                    formData.severity === 'severe' ? 'bg-destructive text-destructive-foreground' :
                    formData.severity === 'moderate' ? 'bg-warning text-warning-foreground' :
                    'bg-success text-success-foreground'
                  }>
                    {severityLevels.find(s => s.id === formData.severity)?.label}
                  </Badge>
                </div>
              )}
              {formData.damageAreas.length > 0 && (
                <div>
                  <span className="text-sm">Áreas afectadas: </span>
                  <span className="text-sm font-medium">{formData.damageAreas.join(", ")}</span>
                </div>
              )}
              {formData.estimatedCost && (
                <div>
                  <span className="text-sm">Costo estimado: </span>
                  <span className="text-sm font-medium">${parseFloat(formData.estimatedCost).toLocaleString('es-ES')}</span>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Actions */}
      <div className="flex justify-between">
        <Button variant="outline">
          Cancelar
        </Button>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleSave}>
            <Save className="h-4 w-4 mr-2" />
            Guardar Borrador
          </Button>
          <Button onClick={handleSubmit}>
            <Send className="h-4 w-4 mr-2" />
            Enviar Evaluación
          </Button>
        </div>
      </div>
    </div>
  );
}