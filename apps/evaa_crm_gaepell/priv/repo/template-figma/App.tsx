import { useState } from "react";
import { AppLayout } from "./components/app-layout";
import { Dashboard } from "./components/dashboard";
import { TruckProfile } from "./components/truck-profile";
import { TicketWizard } from "./components/ticket-wizard";
import { TicketsList } from "./components/tickets-list";
import { DamageEvaluation } from "./components/damage-evaluation";
import { EvaluationTickets } from "./components/evaluation-tickets";
import { MaintenanceTickets } from "./components/maintenance-tickets";
import { TicketDetail } from "./components/ticket-detail";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./components/ui/card";
import { Button } from "./components/ui/button";
import { Toaster } from "./components/ui/sonner";
import { toast } from "sonner@2.0.3";

export default function App() {
  const [activeSection, setActiveSection] = useState("dashboard");
  const [activeSubSection, setActiveSubSection] = useState("");

  const handleNavigate = (section: string, subsection?: string) => {
    setActiveSection(section);
    setActiveSubSection(subsection || "");
  };

  const handleTicketComplete = (ticketData: any) => {
    toast.success("Ticket creado exitosamente", {
      description: `Ticket ${ticketData.truckId} ha sido registrado.`
    });
    setActiveSection("tickets");
    setActiveSubSection("");
  };

  const handleEvaluationSubmit = (evaluationData: any) => {
    toast.success("Evaluación enviada", {
      description: "La evaluación de daños ha sido registrada."
    });
    setActiveSection("evaluations");
    setActiveSubSection("");
  };

  const renderContent = () => {
    switch (activeSection) {
      case "dashboard":
        return <Dashboard onNavigate={handleNavigate} />;
      
      case "trucks":
        if (activeSubSection) {
          return <TruckProfile truckId={activeSubSection} onNavigate={handleNavigate} />;
        }
        return (
          <Card>
            <CardHeader>
              <CardTitle>Gestión de Camiones</CardTitle>
              <CardDescription>Vista principal de la flota de camiones</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground mb-4">
                Funcionalidad en desarrollo. Aquí se mostraría la lista completa de camiones.
              </p>
              <Button onClick={() => handleNavigate("trucks", "TRK-001")}>
                Ver Camión de Ejemplo
              </Button>
            </CardContent>
          </Card>
        );
      
      case "tickets":
        if (activeSubSection === "new") {
          return (
            <TicketWizard 
              onComplete={handleTicketComplete}
              onCancel={() => handleNavigate("tickets")}
            />
          );
        }
        if (activeSubSection === "maintenance") {
          return <MaintenanceTickets onNavigate={handleNavigate} />;
        }
        if (activeSubSection === "evaluations") {
          return <EvaluationTickets onNavigate={handleNavigate} />;
        }
        if (activeSubSection && activeSubSection !== "maintenance" && activeSubSection !== "evaluations") {
          return (
            <TicketDetail 
              ticketId={activeSubSection}
              onBack={() => handleNavigate("tickets")}
              onNavigate={handleNavigate}
            />
          );
        }
        return <TicketsList onNavigate={handleNavigate} />;
      
      case "evaluations":
        if (activeSubSection === "new") {
          return (
            <DamageEvaluation 
              onSubmit={handleEvaluationSubmit}
              onSave={(data) => toast.success("Borrador guardado")}
            />
          );
        }
        if (activeSubSection === "tickets") {
          return <EvaluationTickets onNavigate={handleNavigate} />;
        }
        if (activeSubSection === "maintenance") {
          return <MaintenanceTickets onNavigate={handleNavigate} />;
        }
        if (activeSubSection && activeSubSection !== "tickets" && activeSubSection !== "maintenance" && activeSubSection !== "new") {
          return (
            <TicketDetail 
              ticketId={activeSubSection}
              onBack={() => handleNavigate("evaluations")}
              onNavigate={handleNavigate}
            />
          );
        }
        return <EvaluationTickets onNavigate={handleNavigate} />;
      
      case "documents":
        return (
          <Card>
            <CardHeader>
              <CardTitle>Gestión de Documentos</CardTitle>
              <CardDescription>Archivos y documentos de la flota</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">
                Sistema de gestión documental. Funcionalidad en desarrollo.
              </p>
            </CardContent>
          </Card>
        );
      
      case "settings":
        return (
          <Card>
            <CardHeader>
              <CardTitle>Configuración del Sistema</CardTitle>
              <CardDescription>Ajustes y configuraciones generales</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">
                Panel de configuración y administración. Funcionalidad en desarrollo.
              </p>
            </CardContent>
          </Card>
        );
      
      default:
        return <Dashboard onNavigate={handleNavigate} />;
    }
  };

  return (
    <AppLayout 
      activeSection={activeSection} 
      onNavigate={handleNavigate}
    >
      {renderContent()}
      <Toaster />
    </AppLayout>
  );
}