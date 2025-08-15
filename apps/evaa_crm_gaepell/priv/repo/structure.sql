--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Homebrew)
-- Dumped by pg_dump version 14.18 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activities (
    id bigint NOT NULL,
    business_id bigint NOT NULL,
    user_id bigint,
    contact_id bigint,
    lead_id bigint,
    company_id bigint,
    type character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    due_date timestamp(0) without time zone,
    completed_at timestamp(0) without time zone,
    priority character varying(255) DEFAULT 'medium'::character varying,
    status character varying(255) DEFAULT 'pending'::character varying,
    tags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    service_id bigint,
    specialist_id bigint,
    package_assignment_id bigint,
    service_number integer,
    is_package_service boolean DEFAULT false,
    truck_id bigint,
    maintenance_ticket_id bigint,
    duration_minutes integer DEFAULT 60,
    color character varying(255)
);


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs (
    id uuid NOT NULL,
    entity_type character varying(255) NOT NULL,
    entity_id integer NOT NULL,
    action character varying(255) NOT NULL,
    description text NOT NULL,
    old_values jsonb,
    new_values jsonb,
    metadata jsonb,
    user_id bigint NOT NULL,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: businesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.businesses (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: businesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.businesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: businesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.businesses_id_seq OWNED BY public.businesses.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    business_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    website character varying(255),
    phone character varying(255),
    email character varying(255),
    address text,
    city character varying(255),
    state character varying(255),
    country character varying(255),
    postal_code character varying(255),
    industry character varying(255),
    size character varying(255),
    description text,
    status character varying(255) DEFAULT 'active'::character varying,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id bigint NOT NULL,
    business_id bigint NOT NULL,
    company_id bigint,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    email character varying(255),
    phone character varying(255),
    mobile character varying(255),
    job_title character varying(255),
    department character varying(255),
    address text,
    city character varying(255),
    state character varying(255),
    country character varying(255),
    postal_code character varying(255),
    birth_date date,
    notes text,
    status character varying(255) DEFAULT 'active'::character varying,
    source character varying(255),
    tags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    specialist_id bigint,
    company_name character varying(255)
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: feedback_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_comments (
    id bigint NOT NULL,
    feedback_report_id bigint NOT NULL,
    author character varying(255) NOT NULL,
    body text NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: feedback_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_comments_id_seq OWNED BY public.feedback_comments.id;


--
-- Name: feedback_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_reports (
    id bigint NOT NULL,
    reporter character varying(255) NOT NULL,
    description text NOT NULL,
    severity character varying(255) DEFAULT 'media'::character varying,
    status character varying(255) DEFAULT 'abierto'::character varying,
    photos character varying(255)[] DEFAULT ARRAY[]::character varying[],
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: feedback_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_reports_id_seq OWNED BY public.feedback_reports.id;


--
-- Name: leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads (
    id bigint NOT NULL,
    business_id bigint NOT NULL,
    company_id bigint,
    email character varying(255),
    phone character varying(255),
    company_name character varying(255),
    source character varying(255),
    status character varying(255) DEFAULT 'new'::character varying,
    priority character varying(255) DEFAULT 'medium'::character varying,
    notes text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    name character varying(255),
    assigned_to integer,
    next_follow_up timestamp(0) without time zone,
    conversion_date timestamp(0) without time zone,
    user_id bigint
);


--
-- Name: leads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leads_id_seq OWNED BY public.leads.id;


--
-- Name: maintenance_ticket_checkouts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_ticket_checkouts (
    id bigint NOT NULL,
    maintenance_ticket_id bigint NOT NULL,
    delivered_to_name character varying(255) NOT NULL,
    delivered_to_id_number character varying(255),
    delivered_to_phone character varying(255),
    delivered_at timestamp(0) without time zone NOT NULL,
    photos character varying(255)[] DEFAULT ARRAY[]::character varying[],
    signature text,
    notes text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance_ticket_checkouts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance_ticket_checkouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance_ticket_checkouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance_ticket_checkouts_id_seq OWNED BY public.maintenance_ticket_checkouts.id;


--
-- Name: maintenance_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_tickets (
    id bigint NOT NULL,
    truck_id bigint,
    entry_date timestamp(0) without time zone,
    mileage integer,
    fuel_level character varying(255),
    visible_damage text,
    damage_photos character varying(255)[] DEFAULT ARRAY[]::character varying[],
    responsible_signature text,
    status character varying(255),
    exit_date timestamp(0) without time zone,
    exit_notes text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    title character varying(255),
    description text,
    priority character varying(255) DEFAULT 'medium'::character varying,
    business_id bigint,
    specialist_id bigint,
    color character varying(255),
    signature_url character varying(255),
    deliverer_name character varying(255),
    document_type character varying(255),
    document_number character varying(255),
    deliverer_phone character varying(255),
    deliverer_email character varying(255),
    deliverer_address text,
    company_name character varying(255),
    "position" character varying(255),
    employee_number character varying(255),
    authorization_type character varying(255),
    special_conditions text,
    entry_type character varying(255) DEFAULT 'maintenance'::character varying,
    quotation_id bigint,
    production_status character varying(255) DEFAULT 'pending_quote'::character varying,
    box_type character varying(255),
    estimated_delivery date
);


--
-- Name: maintenance_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance_tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance_tickets_id_seq OWNED BY public.maintenance_tickets.id;


--
-- Name: material_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_categories (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    color character varying(255) DEFAULT '#3b82f6'::character varying,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: material_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.material_categories_id_seq OWNED BY public.material_categories.id;


--
-- Name: materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    unit character varying(255) NOT NULL,
    cost_per_unit numeric(10,2) NOT NULL,
    current_stock numeric(10,2) DEFAULT 0.0,
    min_stock numeric(10,2) DEFAULT 0.0,
    supplier character varying(255),
    supplier_contact text,
    lead_time_days integer DEFAULT 0,
    is_active boolean DEFAULT true NOT NULL,
    business_id bigint NOT NULL,
    category_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;


--
-- Name: package_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.package_assignments (
    id bigint NOT NULL,
    start_date date NOT NULL,
    end_date date,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    notes text,
    package_id bigint NOT NULL,
    contact_id bigint NOT NULL,
    company_id bigint,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: package_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.package_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: package_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.package_assignments_id_seq OWNED BY public.package_assignments.id;


--
-- Name: package_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.package_services (
    id bigint NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    service_order integer DEFAULT 1 NOT NULL,
    package_id bigint NOT NULL,
    service_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: package_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.package_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: package_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.package_services_id_seq OWNED BY public.package_services.id;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packages (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    total_price numeric(10,2) NOT NULL,
    discount_percentage numeric(5,2) DEFAULT 0.0,
    is_active boolean DEFAULT true NOT NULL,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.packages_id_seq OWNED BY public.packages.id;


--
-- Name: production_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_orders (
    id bigint NOT NULL,
    client_name character varying(255) NOT NULL,
    truck_brand character varying(255) NOT NULL,
    truck_model character varying(255) NOT NULL,
    license_plate character varying(255) NOT NULL,
    box_type character varying(255) NOT NULL,
    specifications text,
    estimated_delivery date NOT NULL,
    status character varying(255) DEFAULT 'new_order'::character varying NOT NULL,
    business_id bigint NOT NULL,
    specialist_id bigint,
    workflow_id bigint,
    workflow_state_id bigint,
    notes text,
    actual_delivery_date date,
    total_cost numeric(10,2),
    materials_used text,
    quality_check_notes text,
    customer_signature text,
    photos character varying(255)[],
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    contact_id bigint
);


--
-- Name: production_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.production_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.production_orders_id_seq OWNED BY public.production_orders.id;


--
-- Name: quotation_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotation_options (
    id bigint NOT NULL,
    option_name character varying(255) NOT NULL,
    material_configuration jsonb,
    quality_level character varying(255) NOT NULL,
    production_cost numeric(12,2) NOT NULL,
    markup_percentage numeric(5,2) NOT NULL,
    final_price numeric(12,2) NOT NULL,
    delivery_time_days integer DEFAULT 0,
    is_recommended boolean DEFAULT false,
    quotation_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: quotation_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quotation_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quotation_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quotation_options_id_seq OWNED BY public.quotation_options.id;


--
-- Name: quotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotations (
    id bigint NOT NULL,
    quotation_number character varying(255) NOT NULL,
    client_name character varying(255) NOT NULL,
    client_email character varying(255),
    client_phone character varying(255),
    quantity integer NOT NULL,
    special_requirements text,
    status character varying(255) DEFAULT 'draft'::character varying NOT NULL,
    total_cost numeric(12,2),
    markup_percentage numeric(5,2) DEFAULT 30.0,
    final_price numeric(12,2),
    valid_until date,
    business_id bigint NOT NULL,
    user_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: quotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quotations_id_seq OWNED BY public.quotations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    duration_minutes integer DEFAULT 60 NOT NULL,
    service_type character varying(255) NOT NULL,
    category character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: specialists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialists (
    id bigint NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(255),
    specialization character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    availability character varying(255)
);


--
-- Name: specialists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.specialists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: specialists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.specialists_id_seq OWNED BY public.specialists.id;


--
-- Name: symasoft_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.symasoft_imports (
    id bigint NOT NULL,
    filename character varying(255) NOT NULL,
    file_path character varying(255) NOT NULL,
    content_hash character varying(255) NOT NULL,
    import_status character varying(255) DEFAULT 'pending'::character varying,
    processed_at timestamp(0) without time zone,
    error_message text,
    business_id bigint NOT NULL,
    user_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: symasoft_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.symasoft_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: symasoft_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.symasoft_imports_id_seq OWNED BY public.symasoft_imports.id;


--
-- Name: truck_models; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.truck_models (
    id bigint NOT NULL,
    brand character varying(255) NOT NULL,
    model character varying(255) NOT NULL,
    year integer,
    capacity character varying(255),
    fuel_type character varying(255),
    dimensions character varying(255),
    weight character varying(255),
    engine character varying(255),
    transmission character varying(255),
    usage_count integer DEFAULT 1,
    last_used_at timestamp(0) without time zone,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: truck_models_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.truck_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: truck_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.truck_models_id_seq OWNED BY public.truck_models.id;


--
-- Name: truck_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.truck_notes (
    id bigint NOT NULL,
    content text NOT NULL,
    note_type character varying(255) DEFAULT 'general'::character varying,
    truck_id bigint NOT NULL,
    maintenance_ticket_id bigint,
    production_order_id bigint,
    user_id bigint NOT NULL,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: truck_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.truck_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: truck_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.truck_notes_id_seq OWNED BY public.truck_notes.id;


--
-- Name: truck_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.truck_photos (
    id bigint NOT NULL,
    photo_path character varying(255) NOT NULL,
    description text,
    photo_type character varying(255) DEFAULT 'general'::character varying,
    truck_id bigint NOT NULL,
    maintenance_ticket_id bigint,
    user_id bigint,
    uploaded_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: truck_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.truck_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: truck_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.truck_photos_id_seq OWNED BY public.truck_photos.id;


--
-- Name: trucks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trucks (
    id bigint NOT NULL,
    brand character varying(255),
    model character varying(255),
    license_plate character varying(255),
    chassis_number character varying(255),
    vin character varying(255),
    color character varying(255),
    year integer,
    owner character varying(255),
    general_notes text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    capacity character varying(255),
    fuel_type character varying(255),
    status character varying(255) DEFAULT 'active'::character varying,
    business_id bigint,
    profile_photo character varying(255),
    ficha character varying(255),
    kilometraje integer DEFAULT 0 NOT NULL
);


--
-- Name: trucks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trucks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trucks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trucks_id_seq OWNED BY public.trucks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    business_id bigint NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    company_id bigint,
    specialist_id bigint
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: workflow_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_assignments (
    id bigint NOT NULL,
    workflow_id bigint NOT NULL,
    assignable_type character varying(255) NOT NULL,
    assignable_id integer NOT NULL,
    current_state_id bigint,
    business_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: workflow_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_assignments_id_seq OWNED BY public.workflow_assignments.id;


--
-- Name: workflow_state_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_state_changes (
    id bigint NOT NULL,
    workflow_assignment_id bigint NOT NULL,
    from_state_id bigint,
    to_state_id bigint NOT NULL,
    changed_by_id bigint NOT NULL,
    notes text,
    metadata jsonb DEFAULT '{}'::jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: workflow_state_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_state_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_state_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_state_changes_id_seq OWNED BY public.workflow_state_changes.id;


--
-- Name: workflow_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_states (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    description text,
    order_index integer NOT NULL,
    color character varying(255) DEFAULT '#6B7280'::character varying,
    icon character varying(255),
    workflow_id bigint NOT NULL,
    is_final boolean DEFAULT false,
    is_initial boolean DEFAULT false,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: workflow_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_states_id_seq OWNED BY public.workflow_states.id;


--
-- Name: workflow_transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_transitions (
    id bigint NOT NULL,
    from_state_id bigint NOT NULL,
    to_state_id bigint NOT NULL,
    workflow_id bigint NOT NULL,
    label character varying(255),
    color character varying(255) DEFAULT '#3B82F6'::character varying,
    requires_approval boolean DEFAULT false,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_transitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_transitions_id_seq OWNED BY public.workflow_transitions.id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflows (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    workflow_type character varying(255) NOT NULL,
    business_id bigint NOT NULL,
    is_active boolean DEFAULT true,
    color character varying(255) DEFAULT '#3B82F6'::character varying,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflows_id_seq OWNED BY public.workflows.id;


--
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- Name: businesses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.businesses ALTER COLUMN id SET DEFAULT nextval('public.businesses_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: feedback_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_comments ALTER COLUMN id SET DEFAULT nextval('public.feedback_comments_id_seq'::regclass);


--
-- Name: feedback_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_reports ALTER COLUMN id SET DEFAULT nextval('public.feedback_reports_id_seq'::regclass);


--
-- Name: leads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads ALTER COLUMN id SET DEFAULT nextval('public.leads_id_seq'::regclass);


--
-- Name: maintenance_ticket_checkouts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_ticket_checkouts ALTER COLUMN id SET DEFAULT nextval('public.maintenance_ticket_checkouts_id_seq'::regclass);


--
-- Name: maintenance_tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tickets ALTER COLUMN id SET DEFAULT nextval('public.maintenance_tickets_id_seq'::regclass);


--
-- Name: material_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_categories ALTER COLUMN id SET DEFAULT nextval('public.material_categories_id_seq'::regclass);


--
-- Name: materials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);


--
-- Name: package_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_assignments ALTER COLUMN id SET DEFAULT nextval('public.package_assignments_id_seq'::regclass);


--
-- Name: package_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_services ALTER COLUMN id SET DEFAULT nextval('public.package_services_id_seq'::regclass);


--
-- Name: packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages ALTER COLUMN id SET DEFAULT nextval('public.packages_id_seq'::regclass);


--
-- Name: production_orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_orders ALTER COLUMN id SET DEFAULT nextval('public.production_orders_id_seq'::regclass);


--
-- Name: quotation_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotation_options ALTER COLUMN id SET DEFAULT nextval('public.quotation_options_id_seq'::regclass);


--
-- Name: quotations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations ALTER COLUMN id SET DEFAULT nextval('public.quotations_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: specialists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialists ALTER COLUMN id SET DEFAULT nextval('public.specialists_id_seq'::regclass);


--
-- Name: symasoft_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.symasoft_imports ALTER COLUMN id SET DEFAULT nextval('public.symasoft_imports_id_seq'::regclass);


--
-- Name: truck_models id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_models ALTER COLUMN id SET DEFAULT nextval('public.truck_models_id_seq'::regclass);


--
-- Name: truck_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_notes ALTER COLUMN id SET DEFAULT nextval('public.truck_notes_id_seq'::regclass);


--
-- Name: truck_photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_photos ALTER COLUMN id SET DEFAULT nextval('public.truck_photos_id_seq'::regclass);


--
-- Name: trucks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trucks ALTER COLUMN id SET DEFAULT nextval('public.trucks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: workflow_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments ALTER COLUMN id SET DEFAULT nextval('public.workflow_assignments_id_seq'::regclass);


--
-- Name: workflow_state_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_state_changes ALTER COLUMN id SET DEFAULT nextval('public.workflow_state_changes_id_seq'::regclass);


--
-- Name: workflow_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_states ALTER COLUMN id SET DEFAULT nextval('public.workflow_states_id_seq'::regclass);


--
-- Name: workflow_transitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions ALTER COLUMN id SET DEFAULT nextval('public.workflow_transitions_id_seq'::regclass);


--
-- Name: workflows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflows ALTER COLUMN id SET DEFAULT nextval('public.workflows_id_seq'::regclass);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: businesses businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: feedback_comments feedback_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_comments
    ADD CONSTRAINT feedback_comments_pkey PRIMARY KEY (id);


--
-- Name: feedback_reports feedback_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_reports
    ADD CONSTRAINT feedback_reports_pkey PRIMARY KEY (id);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: maintenance_ticket_checkouts maintenance_ticket_checkouts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_ticket_checkouts
    ADD CONSTRAINT maintenance_ticket_checkouts_pkey PRIMARY KEY (id);


--
-- Name: maintenance_tickets maintenance_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_pkey PRIMARY KEY (id);


--
-- Name: material_categories material_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_categories
    ADD CONSTRAINT material_categories_pkey PRIMARY KEY (id);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: package_assignments package_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_pkey PRIMARY KEY (id);


--
-- Name: package_services package_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_pkey PRIMARY KEY (id);


--
-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: production_orders production_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- Name: quotation_options quotation_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotation_options
    ADD CONSTRAINT quotation_options_pkey PRIMARY KEY (id);


--
-- Name: quotations quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: specialists specialists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_pkey PRIMARY KEY (id);


--
-- Name: symasoft_imports symasoft_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.symasoft_imports
    ADD CONSTRAINT symasoft_imports_pkey PRIMARY KEY (id);


--
-- Name: truck_models truck_models_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_models
    ADD CONSTRAINT truck_models_pkey PRIMARY KEY (id);


--
-- Name: truck_notes truck_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_pkey PRIMARY KEY (id);


--
-- Name: truck_photos truck_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_pkey PRIMARY KEY (id);


--
-- Name: trucks trucks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trucks
    ADD CONSTRAINT trucks_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: workflow_assignments workflow_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_pkey PRIMARY KEY (id);


--
-- Name: workflow_state_changes workflow_state_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_pkey PRIMARY KEY (id);


--
-- Name: workflow_states workflow_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_states
    ADD CONSTRAINT workflow_states_pkey PRIMARY KEY (id);


--
-- Name: workflow_transitions workflow_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_pkey PRIMARY KEY (id);


--
-- Name: workflows workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: activities_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_business_id_index ON public.activities USING btree (business_id);


--
-- Name: activities_company_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_company_id_index ON public.activities USING btree (company_id);


--
-- Name: activities_contact_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_contact_id_index ON public.activities USING btree (contact_id);


--
-- Name: activities_due_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_due_date_index ON public.activities USING btree (due_date);


--
-- Name: activities_is_package_service_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_is_package_service_index ON public.activities USING btree (is_package_service);


--
-- Name: activities_lead_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_lead_id_index ON public.activities USING btree (lead_id);


--
-- Name: activities_package_assignment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_package_assignment_id_index ON public.activities USING btree (package_assignment_id);


--
-- Name: activities_service_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_service_id_index ON public.activities USING btree (service_id);


--
-- Name: activities_specialist_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_specialist_id_index ON public.activities USING btree (specialist_id);


--
-- Name: activities_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_status_index ON public.activities USING btree (status);


--
-- Name: activities_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_type_index ON public.activities USING btree (type);


--
-- Name: activities_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_user_id_index ON public.activities USING btree (user_id);


--
-- Name: activity_logs_action_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_action_index ON public.activity_logs USING btree (action);


--
-- Name: activity_logs_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_business_id_index ON public.activity_logs USING btree (business_id);


--
-- Name: activity_logs_entity_type_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_entity_type_entity_id_index ON public.activity_logs USING btree (entity_type, entity_id);


--
-- Name: activity_logs_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_inserted_at_index ON public.activity_logs USING btree (inserted_at);


--
-- Name: activity_logs_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_user_id_index ON public.activity_logs USING btree (user_id);


--
-- Name: businesses_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX businesses_name_index ON public.businesses USING btree (name);


--
-- Name: companies_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX companies_business_id_index ON public.companies USING btree (business_id);


--
-- Name: companies_business_id_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX companies_business_id_name_index ON public.companies USING btree (business_id, name);


--
-- Name: companies_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX companies_name_index ON public.companies USING btree (name);


--
-- Name: companies_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX companies_status_index ON public.companies USING btree (status);


--
-- Name: contacts_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_business_id_index ON public.contacts USING btree (business_id);


--
-- Name: contacts_company_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_company_id_index ON public.contacts USING btree (company_id);


--
-- Name: contacts_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_email_index ON public.contacts USING btree (email);


--
-- Name: contacts_first_name_last_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_first_name_last_name_index ON public.contacts USING btree (first_name, last_name);


--
-- Name: contacts_specialist_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_specialist_id_index ON public.contacts USING btree (specialist_id);


--
-- Name: contacts_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_status_index ON public.contacts USING btree (status);


--
-- Name: feedback_comments_feedback_report_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX feedback_comments_feedback_report_id_index ON public.feedback_comments USING btree (feedback_report_id);


--
-- Name: leads_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_business_id_index ON public.leads USING btree (business_id);


--
-- Name: leads_company_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_company_id_index ON public.leads USING btree (company_id);


--
-- Name: leads_priority_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_priority_index ON public.leads USING btree (priority);


--
-- Name: leads_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_status_index ON public.leads USING btree (status);


--
-- Name: maintenance_ticket_checkouts_maintenance_ticket_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_ticket_checkouts_maintenance_ticket_id_index ON public.maintenance_ticket_checkouts USING btree (maintenance_ticket_id);


--
-- Name: maintenance_tickets_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_tickets_business_id_index ON public.maintenance_tickets USING btree (business_id);


--
-- Name: maintenance_tickets_specialist_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_tickets_specialist_id_index ON public.maintenance_tickets USING btree (specialist_id);


--
-- Name: maintenance_tickets_truck_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance_tickets_truck_id_index ON public.maintenance_tickets USING btree (truck_id);


--
-- Name: material_categories_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX material_categories_business_id_index ON public.material_categories USING btree (business_id);


--
-- Name: material_categories_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX material_categories_name_index ON public.material_categories USING btree (name);


--
-- Name: materials_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials_business_id_index ON public.materials USING btree (business_id);


--
-- Name: materials_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials_category_id_index ON public.materials USING btree (category_id);


--
-- Name: materials_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials_is_active_index ON public.materials USING btree (is_active);


--
-- Name: materials_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials_name_index ON public.materials USING btree (name);


--
-- Name: materials_supplier_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials_supplier_index ON public.materials USING btree (supplier);


--
-- Name: package_assignments_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX package_assignments_business_id_index ON public.package_assignments USING btree (business_id);


--
-- Name: package_assignments_company_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX package_assignments_company_id_index ON public.package_assignments USING btree (company_id);


--
-- Name: package_assignments_contact_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX package_assignments_contact_id_index ON public.package_assignments USING btree (contact_id);


--
-- Name: package_assignments_package_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX package_assignments_package_id_index ON public.package_assignments USING btree (package_id);


--
-- Name: package_assignments_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX package_assignments_status_index ON public.package_assignments USING btree (status);


--
-- Name: package_services_package_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX package_services_package_id_index ON public.package_services USING btree (package_id);


--
-- Name: package_services_package_id_service_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX package_services_package_id_service_id_index ON public.package_services USING btree (package_id, service_id);


--
-- Name: package_services_service_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX package_services_service_id_index ON public.package_services USING btree (service_id);


--
-- Name: packages_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX packages_business_id_index ON public.packages USING btree (business_id);


--
-- Name: packages_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX packages_is_active_index ON public.packages USING btree (is_active);


--
-- Name: production_orders_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX production_orders_business_id_index ON public.production_orders USING btree (business_id);


--
-- Name: production_orders_contact_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX production_orders_contact_id_index ON public.production_orders USING btree (contact_id);


--
-- Name: production_orders_specialist_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX production_orders_specialist_id_index ON public.production_orders USING btree (specialist_id);


--
-- Name: production_orders_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX production_orders_status_index ON public.production_orders USING btree (status);


--
-- Name: production_orders_workflow_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX production_orders_workflow_id_index ON public.production_orders USING btree (workflow_id);


--
-- Name: production_orders_workflow_state_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX production_orders_workflow_state_id_index ON public.production_orders USING btree (workflow_state_id);


--
-- Name: quotation_options_is_recommended_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotation_options_is_recommended_index ON public.quotation_options USING btree (is_recommended);


--
-- Name: quotation_options_quality_level_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotation_options_quality_level_index ON public.quotation_options USING btree (quality_level);


--
-- Name: quotation_options_quotation_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotation_options_quotation_id_index ON public.quotation_options USING btree (quotation_id);


--
-- Name: quotations_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotations_business_id_index ON public.quotations USING btree (business_id);


--
-- Name: quotations_client_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotations_client_name_index ON public.quotations USING btree (client_name);


--
-- Name: quotations_quotation_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX quotations_quotation_number_index ON public.quotations USING btree (quotation_number);


--
-- Name: quotations_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotations_status_index ON public.quotations USING btree (status);


--
-- Name: quotations_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotations_user_id_index ON public.quotations USING btree (user_id);


--
-- Name: services_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_business_id_index ON public.services USING btree (business_id);


--
-- Name: services_category_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_category_index ON public.services USING btree (category);


--
-- Name: services_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_is_active_index ON public.services USING btree (is_active);


--
-- Name: services_service_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_service_type_index ON public.services USING btree (service_type);


--
-- Name: specialists_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX specialists_business_id_index ON public.specialists USING btree (business_id);


--
-- Name: specialists_email_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX specialists_email_business_id_index ON public.specialists USING btree (email, business_id);


--
-- Name: specialists_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX specialists_is_active_index ON public.specialists USING btree (is_active);


--
-- Name: specialists_specialization_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX specialists_specialization_index ON public.specialists USING btree (specialization);


--
-- Name: specialists_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX specialists_status_index ON public.specialists USING btree (status);


--
-- Name: symasoft_imports_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX symasoft_imports_business_id_index ON public.symasoft_imports USING btree (business_id);


--
-- Name: symasoft_imports_content_hash_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX symasoft_imports_content_hash_index ON public.symasoft_imports USING btree (content_hash);


--
-- Name: symasoft_imports_import_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX symasoft_imports_import_status_index ON public.symasoft_imports USING btree (import_status);


--
-- Name: symasoft_imports_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX symasoft_imports_user_id_index ON public.symasoft_imports USING btree (user_id);


--
-- Name: truck_models_brand_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_models_brand_index ON public.truck_models USING btree (brand);


--
-- Name: truck_models_brand_model_year_business_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX truck_models_brand_model_year_business_index ON public.truck_models USING btree (brand, model, year, business_id);


--
-- Name: truck_models_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_models_business_id_index ON public.truck_models USING btree (business_id);


--
-- Name: truck_models_last_used_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_models_last_used_at_index ON public.truck_models USING btree (last_used_at);


--
-- Name: truck_models_model_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_models_model_index ON public.truck_models USING btree (model);


--
-- Name: truck_models_usage_count_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_models_usage_count_index ON public.truck_models USING btree (usage_count);


--
-- Name: truck_notes_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_notes_business_id_index ON public.truck_notes USING btree (business_id);


--
-- Name: truck_notes_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_notes_inserted_at_index ON public.truck_notes USING btree (inserted_at);


--
-- Name: truck_notes_maintenance_ticket_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_notes_maintenance_ticket_id_index ON public.truck_notes USING btree (maintenance_ticket_id);


--
-- Name: truck_notes_production_order_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_notes_production_order_id_index ON public.truck_notes USING btree (production_order_id);


--
-- Name: truck_notes_truck_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_notes_truck_id_index ON public.truck_notes USING btree (truck_id);


--
-- Name: truck_notes_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_notes_user_id_index ON public.truck_notes USING btree (user_id);


--
-- Name: truck_photos_maintenance_ticket_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_photos_maintenance_ticket_id_index ON public.truck_photos USING btree (maintenance_ticket_id);


--
-- Name: truck_photos_photo_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_photos_photo_type_index ON public.truck_photos USING btree (photo_type);


--
-- Name: truck_photos_truck_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_photos_truck_id_index ON public.truck_photos USING btree (truck_id);


--
-- Name: truck_photos_uploaded_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_photos_uploaded_at_index ON public.truck_photos USING btree (uploaded_at);


--
-- Name: truck_photos_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX truck_photos_user_id_index ON public.truck_photos USING btree (user_id);


--
-- Name: trucks_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trucks_business_id_index ON public.trucks USING btree (business_id);


--
-- Name: users_business_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_business_id_index ON public.users USING btree (business_id);


--
-- Name: users_company_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_company_id_index ON public.users USING btree (company_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_specialist_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_specialist_id_index ON public.users USING btree (specialist_id);


--
-- Name: workflow_assignments_assignable_type_assignable_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_assignments_assignable_type_assignable_id_index ON public.workflow_assignments USING btree (assignable_type, assignable_id);


--
-- Name: workflow_assignments_workflow_id_current_state_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_assignments_workflow_id_current_state_id_index ON public.workflow_assignments USING btree (workflow_id, current_state_id);


--
-- Name: workflow_state_changes_changed_by_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_state_changes_changed_by_id_index ON public.workflow_state_changes USING btree (changed_by_id);


--
-- Name: workflow_state_changes_workflow_assignment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_state_changes_workflow_assignment_id_index ON public.workflow_state_changes USING btree (workflow_assignment_id);


--
-- Name: workflow_states_workflow_id_order_index_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_states_workflow_id_order_index_index ON public.workflow_states USING btree (workflow_id, order_index);


--
-- Name: workflow_transitions_workflow_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_transitions_workflow_id_index ON public.workflow_transitions USING btree (workflow_id);


--
-- Name: workflows_business_id_workflow_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflows_business_id_workflow_type_index ON public.workflows USING btree (business_id, workflow_type);


--
-- Name: activities activities_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: activities activities_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: activities activities_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: activities activities_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: activities activities_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE SET NULL;


--
-- Name: activities activities_package_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_package_assignment_id_fkey FOREIGN KEY (package_assignment_id) REFERENCES public.package_assignments(id) ON DELETE RESTRICT;


--
-- Name: activities activities_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE RESTRICT;


--
-- Name: activities activities_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE RESTRICT;


--
-- Name: activities activities_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE SET NULL;


--
-- Name: activities activities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: activity_logs activity_logs_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id);


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: companies companies_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: contacts contacts_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: contacts contacts_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: contacts contacts_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: feedback_comments feedback_comments_feedback_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_comments
    ADD CONSTRAINT feedback_comments_feedback_report_id_fkey FOREIGN KEY (feedback_report_id) REFERENCES public.feedback_reports(id) ON DELETE CASCADE;


--
-- Name: leads leads_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: leads leads_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: leads leads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: maintenance_ticket_checkouts maintenance_ticket_checkouts_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_ticket_checkouts
    ADD CONSTRAINT maintenance_ticket_checkouts_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE CASCADE;


--
-- Name: maintenance_tickets maintenance_tickets_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: maintenance_tickets maintenance_tickets_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_quotation_id_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotations(id);


--
-- Name: maintenance_tickets maintenance_tickets_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: maintenance_tickets maintenance_tickets_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE CASCADE;


--
-- Name: material_categories material_categories_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_categories
    ADD CONSTRAINT material_categories_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: materials materials_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: materials materials_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.material_categories(id) ON DELETE CASCADE;


--
-- Name: package_assignments package_assignments_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: package_assignments package_assignments_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE RESTRICT;


--
-- Name: package_assignments package_assignments_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: package_assignments package_assignments_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id) ON DELETE RESTRICT;


--
-- Name: package_services package_services_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id) ON DELETE CASCADE;


--
-- Name: package_services package_services_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: packages packages_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: production_orders production_orders_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: production_orders production_orders_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: production_orders production_orders_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: production_orders production_orders_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE SET NULL;


--
-- Name: production_orders production_orders_workflow_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_workflow_state_id_fkey FOREIGN KEY (workflow_state_id) REFERENCES public.workflow_states(id) ON DELETE SET NULL;


--
-- Name: quotation_options quotation_options_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotation_options
    ADD CONSTRAINT quotation_options_quotation_id_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotations(id) ON DELETE CASCADE;


--
-- Name: quotations quotations_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: quotations quotations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: services services_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: specialists specialists_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: symasoft_imports symasoft_imports_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.symasoft_imports
    ADD CONSTRAINT symasoft_imports_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: symasoft_imports symasoft_imports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.symasoft_imports
    ADD CONSTRAINT symasoft_imports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: truck_models truck_models_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_models
    ADD CONSTRAINT truck_models_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: truck_notes truck_notes_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: truck_notes truck_notes_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE SET NULL;


--
-- Name: truck_notes truck_notes_production_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_production_order_id_fkey FOREIGN KEY (production_order_id) REFERENCES public.production_orders(id) ON DELETE SET NULL;


--
-- Name: truck_notes truck_notes_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE CASCADE;


--
-- Name: truck_notes truck_notes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: truck_photos truck_photos_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE SET NULL;


--
-- Name: truck_photos truck_photos_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE CASCADE;


--
-- Name: truck_photos truck_photos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: trucks trucks_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trucks
    ADD CONSTRAINT trucks_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: users users_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: users users_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: users users_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: workflow_assignments workflow_assignments_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: workflow_assignments workflow_assignments_current_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_current_state_id_fkey FOREIGN KEY (current_state_id) REFERENCES public.workflow_states(id) ON DELETE RESTRICT;


--
-- Name: workflow_assignments workflow_assignments_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE CASCADE;


--
-- Name: workflow_state_changes workflow_state_changes_changed_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_changed_by_id_fkey FOREIGN KEY (changed_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: workflow_state_changes workflow_state_changes_from_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_from_state_id_fkey FOREIGN KEY (from_state_id) REFERENCES public.workflow_states(id) ON DELETE RESTRICT;


--
-- Name: workflow_state_changes workflow_state_changes_to_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_to_state_id_fkey FOREIGN KEY (to_state_id) REFERENCES public.workflow_states(id) ON DELETE RESTRICT;


--
-- Name: workflow_state_changes workflow_state_changes_workflow_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_workflow_assignment_id_fkey FOREIGN KEY (workflow_assignment_id) REFERENCES public.workflow_assignments(id) ON DELETE CASCADE;


--
-- Name: workflow_states workflow_states_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_states
    ADD CONSTRAINT workflow_states_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE CASCADE;


--
-- Name: workflow_transitions workflow_transitions_from_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_from_state_id_fkey FOREIGN KEY (from_state_id) REFERENCES public.workflow_states(id) ON DELETE CASCADE;


--
-- Name: workflow_transitions workflow_transitions_to_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_to_state_id_fkey FOREIGN KEY (to_state_id) REFERENCES public.workflow_states(id) ON DELETE CASCADE;


--
-- Name: workflow_transitions workflow_transitions_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE CASCADE;


--
-- Name: workflows workflows_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20250629004315);
INSERT INTO public."schema_migrations" (version) VALUES (20250629004325);
INSERT INTO public."schema_migrations" (version) VALUES (20250629012049);
INSERT INTO public."schema_migrations" (version) VALUES (20250629012054);
INSERT INTO public."schema_migrations" (version) VALUES (20250629012058);
INSERT INTO public."schema_migrations" (version) VALUES (20250629012103);
INSERT INTO public."schema_migrations" (version) VALUES (20250629044744);
INSERT INTO public."schema_migrations" (version) VALUES (20250629044749);
INSERT INTO public."schema_migrations" (version) VALUES (20250629044759);
INSERT INTO public."schema_migrations" (version) VALUES (20250629044810);
INSERT INTO public."schema_migrations" (version) VALUES (20250629044821);
INSERT INTO public."schema_migrations" (version) VALUES (20250629044910);
INSERT INTO public."schema_migrations" (version) VALUES (20250629054924);
INSERT INTO public."schema_migrations" (version) VALUES (20250629063737);
INSERT INTO public."schema_migrations" (version) VALUES (20250629071737);
INSERT INTO public."schema_migrations" (version) VALUES (20250629074527);
INSERT INTO public."schema_migrations" (version) VALUES (20250702212035);
INSERT INTO public."schema_migrations" (version) VALUES (20250702212039);
INSERT INTO public."schema_migrations" (version) VALUES (20250703002637);
INSERT INTO public."schema_migrations" (version) VALUES (20250703041707);
INSERT INTO public."schema_migrations" (version) VALUES (20250703044244);
INSERT INTO public."schema_migrations" (version) VALUES (20250703052234);
INSERT INTO public."schema_migrations" (version) VALUES (20250703052237);
INSERT INTO public."schema_migrations" (version) VALUES (20250703120000);
INSERT INTO public."schema_migrations" (version) VALUES (20250703120100);
INSERT INTO public."schema_migrations" (version) VALUES (20250703120200);
INSERT INTO public."schema_migrations" (version) VALUES (20250705000001);
INSERT INTO public."schema_migrations" (version) VALUES (20250705000002);
INSERT INTO public."schema_migrations" (version) VALUES (20250705000003);
INSERT INTO public."schema_migrations" (version) VALUES (20250705000004);
INSERT INTO public."schema_migrations" (version) VALUES (20250705031010);
INSERT INTO public."schema_migrations" (version) VALUES (20250705031015);
INSERT INTO public."schema_migrations" (version) VALUES (20250705031046);
INSERT INTO public."schema_migrations" (version) VALUES (20250706003000);
INSERT INTO public."schema_migrations" (version) VALUES (20250706003046);
INSERT INTO public."schema_migrations" (version) VALUES (20250706055849);
INSERT INTO public."schema_migrations" (version) VALUES (20250706094411);
INSERT INTO public."schema_migrations" (version) VALUES (20250707000000);
INSERT INTO public."schema_migrations" (version) VALUES (20250707000001);
INSERT INTO public."schema_migrations" (version) VALUES (20250713082931);
INSERT INTO public."schema_migrations" (version) VALUES (20250713205250);
INSERT INTO public."schema_migrations" (version) VALUES (20250719043922);
INSERT INTO public."schema_migrations" (version) VALUES (20250719061816);
INSERT INTO public."schema_migrations" (version) VALUES (20250721000000);
INSERT INTO public."schema_migrations" (version) VALUES (20250721000100);
INSERT INTO public."schema_migrations" (version) VALUES (20250725000000);
INSERT INTO public."schema_migrations" (version) VALUES (20250801050000);
INSERT INTO public."schema_migrations" (version) VALUES (20250801050001);
INSERT INTO public."schema_migrations" (version) VALUES (20250801050002);
INSERT INTO public."schema_migrations" (version) VALUES (20250801050003);
INSERT INTO public."schema_migrations" (version) VALUES (20250801190906);
INSERT INTO public."schema_migrations" (version) VALUES (20250805233853);
INSERT INTO public."schema_migrations" (version) VALUES (20250805235411);
INSERT INTO public."schema_migrations" (version) VALUES (20250806065351);
INSERT INTO public."schema_migrations" (version) VALUES (20250806074926);
INSERT INTO public."schema_migrations" (version) VALUES (20250807191600);
INSERT INTO public."schema_migrations" (version) VALUES (20250808150940);
