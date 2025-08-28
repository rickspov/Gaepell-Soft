import { Badge } from "./ui/badge";
import { cn } from "./ui/utils";

type Status = "pending" | "in-progress" | "completed" | "cancelled";

interface StatusBadgeProps {
  status: Status;
  className?: string;
}

const statusConfig = {
  pending: {
    label: "Pendiente",
    className: "gradient-primary text-black border-0 shadow-md"
  },
  "in-progress": {
    label: "En Progreso",
    className: "gradient-info text-white border-0 shadow-md"
  },
  completed: {
    label: "Completado",
    className: "gradient-success text-white border-0 shadow-md"
  },
  cancelled: {
    label: "Cancelado",
    className: "gradient-danger text-white border-0 shadow-md"
  }
};

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = statusConfig[status];
  
  return (
    <Badge className={cn(config.className, "px-3 py-1 font-medium text-xs", className)}>
      {config.label}
    </Badge>
  );
}