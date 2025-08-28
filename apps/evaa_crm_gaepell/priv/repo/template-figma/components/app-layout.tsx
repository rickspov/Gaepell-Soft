import { useState } from "react";
import { Button } from "./ui/button";
import { 
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarTrigger
} from "./ui/sidebar";
import { 
  Home,
  Truck,
  Wrench,
  FileText,
  ClipboardList,
  Settings,
  Bell,
  User,
  Search,
  Sun,
  Moon
} from "lucide-react";
import { Badge } from "./ui/badge";
import { Input } from "./ui/input";

interface AppLayoutProps {
  children: React.ReactNode;
  activeSection?: string;
  onNavigate?: (section: string) => void;
}

const navigationItems = [
  {
    title: "Dashboard",
    url: "dashboard",
    icon: Home,
  },
  {
    title: "Camiones",
    url: "trucks",
    icon: Truck,
  },
  {
    title: "Tickets",
    url: "tickets",
    icon: Wrench,
  },
  {
    title: "Evaluaciones",
    url: "evaluations",
    icon: ClipboardList,
  },
  {
    title: "Documentos",
    url: "documents",
    icon: FileText,
  },
  {
    title: "Configuración",
    url: "settings",
    icon: Settings,
  },
];

export function AppLayout({ children, activeSection = "dashboard", onNavigate }: AppLayoutProps) {
  const [isDark, setIsDark] = useState(false);

  const toggleTheme = () => {
    setIsDark(!isDark);
    document.documentElement.classList.toggle('dark');
  };

  return (
    <SidebarProvider>
      <div className={`flex min-h-screen w-full bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-950 dark:to-slate-900`}>
        {/* Sidebar Moderno */}
        <Sidebar className="border-r border-slate-200/60 dark:border-slate-700/60 bg-white/70 dark:bg-slate-900/70 backdrop-blur-xl">
          <SidebarContent>
            {/* Logo Moderno con color del logo */}
            <div className="flex items-center gap-3 p-6 border-b border-slate-200/60 dark:border-slate-700/60">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl gradient-primary shadow-lg shadow-gold">
                <Truck className="h-5 w-5 text-black dark:text-black" />
              </div>
              <div>
                <span className="text-lg font-semibold bg-gradient-to-r from-slate-900 to-slate-700 dark:from-slate-100 dark:to-slate-300 bg-clip-text text-transparent">
                  FleetCRM
                </span>
                <p className="text-xs text-slate-500 dark:text-slate-400">Gestión Inteligente</p>
              </div>
            </div>

            {/* Búsqueda */}
            <div className="p-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                <Input 
                  placeholder="Buscar..." 
                  className="pl-9 bg-slate-50/50 dark:bg-slate-800/50 border-slate-200/60 dark:border-slate-700/60 focus:bg-white dark:focus:bg-slate-800 transition-colors"
                />
              </div>
            </div>

            <SidebarGroup>
              <SidebarGroupLabel className="text-slate-600 dark:text-slate-400 font-medium px-4">
                Navegación Principal
              </SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu className="px-2">
                  {navigationItems.map((item) => (
                    <SidebarMenuItem key={item.title}>
                      <SidebarMenuButton 
                        onClick={() => onNavigate?.(item.url)}
                        isActive={activeSection === item.url}
                        className={`w-full mx-2 mb-1 rounded-xl transition-all duration-200 hover-lift ${
                          activeSection === item.url 
                            ? 'gradient-primary text-black dark:text-black shadow-lg shadow-gold' 
                            : 'hover:bg-slate-50 dark:hover:bg-slate-800/50 hover:shadow-md'
                        }`}
                      >
                        <item.icon className={`h-5 w-5 ${
                          activeSection === item.url ? 'text-black dark:text-black' : 'text-slate-600 dark:text-slate-400'
                        }`} />
                        <span className={activeSection === item.url ? 'text-black dark:text-black font-medium' : 'text-slate-700 dark:text-slate-300'}>
                          {item.title}
                        </span>
                        {item.url === "tickets" && (
                          <Badge 
                            variant="secondary" 
                            className={`ml-auto ${
                              activeSection === item.url 
                                ? 'bg-black/10 text-black dark:text-black border-black/20' 
                                : 'bg-red-100 dark:bg-red-900/50 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800'
                            }`}
                          >
                            12
                          </Badge>
                        )}
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  ))}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>

            {/* Usuario Info */}
            <div className="mt-auto p-4 border-t border-slate-200/60 dark:border-slate-700/60">
              <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-50/50 dark:bg-slate-800/50 hover:bg-slate-100/50 dark:hover:bg-slate-700/50 transition-colors cursor-pointer">
                <div className="h-8 w-8 rounded-full gradient-gold-blue flex items-center justify-center">
                  <User className="h-4 w-4 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-900 dark:text-slate-100 truncate">Admin User</p>
                  <p className="text-xs text-slate-500 dark:text-slate-400 truncate">admin@fleetcrm.com</p>
                </div>
              </div>
            </div>
          </SidebarContent>
        </Sidebar>

        {/* Main Content */}
        <div className="flex-1 flex flex-col overflow-hidden">
          {/* Header Moderno */}
          <header className="border-b border-slate-200/60 dark:border-slate-700/60 bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl px-6 py-4 shadow-sm">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <SidebarTrigger className="hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors" />
                <div>
                  <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-100">
                    {navigationItems.find(item => item.url === activeSection)?.title || "Dashboard"}
                  </h1>
                  <p className="text-sm text-slate-500 dark:text-slate-400">
                    Gestión eficiente de tu flota de camiones
                  </p>
                </div>
              </div>
              
              <div className="flex items-center gap-3">
                {/* Theme Toggle */}
                <Button 
                  variant="ghost" 
                  size="sm" 
                  onClick={toggleTheme}
                  className="hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors theme-toggle"
                >
                  {isDark ? (
                    <Sun className="h-5 w-5 text-slate-600 dark:text-slate-400" />
                  ) : (
                    <Moon className="h-5 w-5 text-slate-600 dark:text-slate-400" />
                  )}
                </Button>
                <Button variant="ghost" size="sm" className="relative hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg">
                  <Bell className="h-5 w-5 text-slate-600 dark:text-slate-400" />
                  <span className="absolute -top-1 -right-1 h-3 w-3 bg-red-500 rounded-full text-xs flex items-center justify-center">
                    <span className="w-1.5 h-1.5 bg-white rounded-full"></span>
                  </span>
                </Button>
                <Button variant="ghost" size="sm" className="hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg">
                  <User className="h-5 w-5 text-slate-600 dark:text-slate-400" />
                </Button>
              </div>
            </div>
          </header>

          {/* Page Content */}
          <main className="flex-1 overflow-auto p-6 bg-gradient-to-br from-slate-50/50 to-white dark:from-slate-950/50 dark:to-slate-900">
            <div className="max-w-7xl mx-auto">
              {children}
            </div>
          </main>
        </div>
      </div>
    </SidebarProvider>
  );
}