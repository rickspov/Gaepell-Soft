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
-- Name: activities; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.activities OWNER TO postgres;

--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.activities_id_seq OWNER TO postgres;

--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- Name: businesses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.businesses (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.businesses OWNER TO postgres;

--
-- Name: businesses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.businesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.businesses_id_seq OWNER TO postgres;

--
-- Name: businesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.businesses_id_seq OWNED BY public.businesses.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.companies OWNER TO postgres;

--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.companies_id_seq OWNER TO postgres;

--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.contacts OWNER TO postgres;

--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contacts_id_seq OWNER TO postgres;

--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: feedback_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.feedback_comments (
    id bigint NOT NULL,
    feedback_report_id bigint NOT NULL,
    author character varying(255) NOT NULL,
    body text NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.feedback_comments OWNER TO postgres;

--
-- Name: feedback_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.feedback_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.feedback_comments_id_seq OWNER TO postgres;

--
-- Name: feedback_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.feedback_comments_id_seq OWNED BY public.feedback_comments.id;


--
-- Name: feedback_reports; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.feedback_reports OWNER TO postgres;

--
-- Name: feedback_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.feedback_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.feedback_reports_id_seq OWNER TO postgres;

--
-- Name: feedback_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.feedback_reports_id_seq OWNED BY public.feedback_reports.id;


--
-- Name: leads; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.leads OWNER TO postgres;

--
-- Name: leads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leads_id_seq OWNER TO postgres;

--
-- Name: leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.leads_id_seq OWNED BY public.leads.id;


--
-- Name: maintenance_ticket_checkouts; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.maintenance_ticket_checkouts OWNER TO postgres;

--
-- Name: maintenance_ticket_checkouts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.maintenance_ticket_checkouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.maintenance_ticket_checkouts_id_seq OWNER TO postgres;

--
-- Name: maintenance_ticket_checkouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.maintenance_ticket_checkouts_id_seq OWNED BY public.maintenance_ticket_checkouts.id;


--
-- Name: maintenance_tickets; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.maintenance_tickets OWNER TO postgres;

--
-- Name: maintenance_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.maintenance_tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.maintenance_tickets_id_seq OWNER TO postgres;

--
-- Name: maintenance_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.maintenance_tickets_id_seq OWNED BY public.maintenance_tickets.id;


--
-- Name: material_categories; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.material_categories OWNER TO postgres;

--
-- Name: material_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.material_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.material_categories_id_seq OWNER TO postgres;

--
-- Name: material_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.material_categories_id_seq OWNED BY public.material_categories.id;


--
-- Name: materials; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.materials OWNER TO postgres;

--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.materials_id_seq OWNER TO postgres;

--
-- Name: materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;


--
-- Name: package_assignments; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.package_assignments OWNER TO postgres;

--
-- Name: package_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.package_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.package_assignments_id_seq OWNER TO postgres;

--
-- Name: package_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.package_assignments_id_seq OWNED BY public.package_assignments.id;


--
-- Name: package_services; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.package_services OWNER TO postgres;

--
-- Name: package_services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.package_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.package_services_id_seq OWNER TO postgres;

--
-- Name: package_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.package_services_id_seq OWNED BY public.package_services.id;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.packages OWNER TO postgres;

--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.packages_id_seq OWNER TO postgres;

--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.packages_id_seq OWNED BY public.packages.id;


--
-- Name: production_orders; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.production_orders OWNER TO postgres;

--
-- Name: production_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.production_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.production_orders_id_seq OWNER TO postgres;

--
-- Name: production_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.production_orders_id_seq OWNED BY public.production_orders.id;


--
-- Name: quotation_options; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.quotation_options OWNER TO postgres;

--
-- Name: quotation_options_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quotation_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotation_options_id_seq OWNER TO postgres;

--
-- Name: quotation_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quotation_options_id_seq OWNED BY public.quotation_options.id;


--
-- Name: quotations; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.quotations OWNER TO postgres;

--
-- Name: quotations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotations_id_seq OWNER TO postgres;

--
-- Name: quotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quotations_id_seq OWNED BY public.quotations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: services; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.services OWNER TO postgres;

--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.services_id_seq OWNER TO postgres;

--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: specialists; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.specialists OWNER TO postgres;

--
-- Name: specialists_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.specialists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.specialists_id_seq OWNER TO postgres;

--
-- Name: specialists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.specialists_id_seq OWNED BY public.specialists.id;


--
-- Name: symasoft_imports; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.symasoft_imports OWNER TO postgres;

--
-- Name: symasoft_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.symasoft_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.symasoft_imports_id_seq OWNER TO postgres;

--
-- Name: symasoft_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.symasoft_imports_id_seq OWNED BY public.symasoft_imports.id;


--
-- Name: truck_models; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.truck_models OWNER TO postgres;

--
-- Name: truck_models_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.truck_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.truck_models_id_seq OWNER TO postgres;

--
-- Name: truck_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.truck_models_id_seq OWNED BY public.truck_models.id;


--
-- Name: truck_notes; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.truck_notes OWNER TO postgres;

--
-- Name: truck_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.truck_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.truck_notes_id_seq OWNER TO postgres;

--
-- Name: truck_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.truck_notes_id_seq OWNED BY public.truck_notes.id;


--
-- Name: truck_photos; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.truck_photos OWNER TO postgres;

--
-- Name: truck_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.truck_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.truck_photos_id_seq OWNER TO postgres;

--
-- Name: truck_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.truck_photos_id_seq OWNED BY public.truck_photos.id;


--
-- Name: trucks; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.trucks OWNER TO postgres;

--
-- Name: trucks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trucks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trucks_id_seq OWNER TO postgres;

--
-- Name: trucks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trucks_id_seq OWNED BY public.trucks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: workflow_assignments; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.workflow_assignments OWNER TO postgres;

--
-- Name: workflow_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflow_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_assignments_id_seq OWNER TO postgres;

--
-- Name: workflow_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflow_assignments_id_seq OWNED BY public.workflow_assignments.id;


--
-- Name: workflow_state_changes; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.workflow_state_changes OWNER TO postgres;

--
-- Name: workflow_state_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflow_state_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_state_changes_id_seq OWNER TO postgres;

--
-- Name: workflow_state_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflow_state_changes_id_seq OWNED BY public.workflow_state_changes.id;


--
-- Name: workflow_states; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.workflow_states OWNER TO postgres;

--
-- Name: workflow_states_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflow_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_states_id_seq OWNER TO postgres;

--
-- Name: workflow_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflow_states_id_seq OWNED BY public.workflow_states.id;


--
-- Name: workflow_transitions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.workflow_transitions OWNER TO postgres;

--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflow_transitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_transitions_id_seq OWNER TO postgres;

--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflow_transitions_id_seq OWNED BY public.workflow_transitions.id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.workflows OWNER TO postgres;

--
-- Name: workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflows_id_seq OWNER TO postgres;

--
-- Name: workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflows_id_seq OWNED BY public.workflows.id;


--
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- Name: businesses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.businesses ALTER COLUMN id SET DEFAULT nextval('public.businesses_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: feedback_comments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_comments ALTER COLUMN id SET DEFAULT nextval('public.feedback_comments_id_seq'::regclass);


--
-- Name: feedback_reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_reports ALTER COLUMN id SET DEFAULT nextval('public.feedback_reports_id_seq'::regclass);


--
-- Name: leads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads ALTER COLUMN id SET DEFAULT nextval('public.leads_id_seq'::regclass);


--
-- Name: maintenance_ticket_checkouts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_ticket_checkouts ALTER COLUMN id SET DEFAULT nextval('public.maintenance_ticket_checkouts_id_seq'::regclass);


--
-- Name: maintenance_tickets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_tickets ALTER COLUMN id SET DEFAULT nextval('public.maintenance_tickets_id_seq'::regclass);


--
-- Name: material_categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_categories ALTER COLUMN id SET DEFAULT nextval('public.material_categories_id_seq'::regclass);


--
-- Name: materials id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);


--
-- Name: package_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_assignments ALTER COLUMN id SET DEFAULT nextval('public.package_assignments_id_seq'::regclass);


--
-- Name: package_services id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_services ALTER COLUMN id SET DEFAULT nextval('public.package_services_id_seq'::regclass);


--
-- Name: packages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.packages ALTER COLUMN id SET DEFAULT nextval('public.packages_id_seq'::regclass);


--
-- Name: production_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders ALTER COLUMN id SET DEFAULT nextval('public.production_orders_id_seq'::regclass);


--
-- Name: quotation_options id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quotation_options ALTER COLUMN id SET DEFAULT nextval('public.quotation_options_id_seq'::regclass);


--
-- Name: quotations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quotations ALTER COLUMN id SET DEFAULT nextval('public.quotations_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: specialists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialists ALTER COLUMN id SET DEFAULT nextval('public.specialists_id_seq'::regclass);


--
-- Name: symasoft_imports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symasoft_imports ALTER COLUMN id SET DEFAULT nextval('public.symasoft_imports_id_seq'::regclass);


--
-- Name: truck_models id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_models ALTER COLUMN id SET DEFAULT nextval('public.truck_models_id_seq'::regclass);


--
-- Name: truck_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_notes ALTER COLUMN id SET DEFAULT nextval('public.truck_notes_id_seq'::regclass);


--
-- Name: truck_photos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_photos ALTER COLUMN id SET DEFAULT nextval('public.truck_photos_id_seq'::regclass);


--
-- Name: trucks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trucks ALTER COLUMN id SET DEFAULT nextval('public.trucks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: workflow_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_assignments ALTER COLUMN id SET DEFAULT nextval('public.workflow_assignments_id_seq'::regclass);


--
-- Name: workflow_state_changes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state_changes ALTER COLUMN id SET DEFAULT nextval('public.workflow_state_changes_id_seq'::regclass);


--
-- Name: workflow_states id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_states ALTER COLUMN id SET DEFAULT nextval('public.workflow_states_id_seq'::regclass);


--
-- Name: workflow_transitions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_transitions ALTER COLUMN id SET DEFAULT nextval('public.workflow_transitions_id_seq'::regclass);


--
-- Name: workflows id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows ALTER COLUMN id SET DEFAULT nextval('public.workflows_id_seq'::regclass);


--
-- Data for Name: activities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activities (id, business_id, user_id, contact_id, lead_id, company_id, type, title, description, due_date, completed_at, priority, status, tags, inserted_at, updated_at, service_id, specialist_id, package_assignment_id, service_number, is_package_service, truck_id, maintenance_ticket_id, duration_minutes, color) FROM stdin;
72	1	\N	\N	\N	\N	maintenance	Nuevo	Entregador: Chichi | Doc: Licencia 00110228145 | Tel: 8092891818 | Email: gpp.jr@claro.net.do | Empresa: H Alimento | Cargo: Conductor | KM: 100 | Combustible: Vacío	2025-07-31 15:51:00	\N	medium	pending	{}	2025-08-01 19:53:12	2025-08-01 19:53:12	\N	\N	\N	\N	f	15	71	60	#3b82f6
\.


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, entity_type, entity_id, action, description, old_values, new_values, metadata, user_id, business_id, inserted_at, updated_at) FROM stdin;
a67ac76b-f851-4ac8-b82d-6e05faa4aa4b	maintenance_ticket	1	created	creó ticket de mantenimiento 'Ticket de prueba'	\N	\N	\N	1	1	2025-07-13 08:34:18	2025-07-13 08:34:18
3cbdcec1-8ad6-4f1c-8705-2f8c994b4f26	maintenance_ticket	1	status_changed	Estado cambiado de 'check_in' a 'in_workshop'	{"status": "check_in"}	{"status": "in_workshop"}	\N	1	1	2025-07-13 08:34:18	2025-07-13 08:34:18
50543f0e-684b-4595-b7d9-6527f6af4717	maintenance_ticket	1	commented	agregó un comentario	\N	\N	{"comment": "Este es un comentario de prueba"}	1	1	2025-07-13 08:34:18	2025-07-13 08:34:18
4fdfe00d-6c17-4e7f-aa8c-94a133e4b589	maintenance_ticket	11	created	creó ticket de mantenimiento 'Ticket de prueba para logs'	\N	\N	\N	1	1	2025-07-13 08:44:27	2025-07-13 08:44:27
42c220c1-89c8-4920-9cd4-ccaae2e3224f	maintenance_ticket	11	status_changed	Estado cambiado de 'check_in' a 'in_workshop'	{"status": "check_in"}	{"status": "in_workshop"}	\N	1	1	2025-07-13 08:44:27	2025-07-13 08:44:27
1bd34052-075d-4537-91d0-238797588858	maintenance_ticket	1	status_changed	Estado cambiado de 'in_workshop' a 'final_review'	{"status": "in_workshop"}	{"status": "final_review"}	\N	1	1	2025-07-13 08:49:29	2025-07-13 08:49:29
0be2f318-3dbf-4a1b-b4fe-1213fb0ccede	maintenance_ticket	1	status_changed	Estado cambiado de 'in_workshop' a 'car_wash'	{"status": "in_workshop"}	{"status": "car_wash"}	\N	1	1	2025-07-13 08:49:29	2025-07-13 08:49:29
fd0cc2da-5766-4f09-96d6-daacd8309555	maintenance_ticket	1	status_changed	Estado cambiado de 'in_workshop' a 'check_out'	{"status": "in_workshop"}	{"status": "check_out"}	\N	1	1	2025-07-13 08:49:29	2025-07-13 08:49:29
392277e8-5ec3-4823-9845-79052705fbbc	maintenance_ticket	11	status_changed	Estado cambiado de 'in_workshop' a 'final_review'	{"status": "in_workshop"}	{"status": "final_review"}	\N	1	1	2025-07-13 08:52:31	2025-07-13 08:52:31
ff4b9ad8-48a3-47b3-8308-fcae8e4bc481	maintenance_ticket	11	status_changed	Estado cambiado de 'final_review' a 'car_wash'	{"status": "final_review"}	{"status": "car_wash"}	\N	1	1	2025-07-13 08:52:35	2025-07-13 08:52:35
be26bb90-fa90-42c5-aa81-51aec9c41688	maintenance_ticket	11	status_changed	Estado cambiado de 'car_wash' a 'in_workshop'	{"status": "car_wash"}	{"status": "in_workshop"}	\N	1	1	2025-07-13 18:05:17	2025-07-13 18:05:17
a9954a0e-8a1e-47b0-b0e2-4d0b091a924d	maintenance_ticket	17	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 16:31:24	2025-07-17 16:31:24
769af1b7-c516-423a-922d-4a6284467c0b	maintenance_ticket	18	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 16:44:35	2025-07-17 16:44:35
db56f0d1-1cc6-4f8b-b0e2-46cfee40428a	maintenance_ticket	19	created	creó ticket de mantenimiento 'Check-in de camión ABC-123'	\N	\N	\N	1	2	2025-07-17 16:45:22	2025-07-17 16:45:22
1e27b135-617e-4cda-8fd0-f0be94361787	maintenance_ticket	20	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 16:47:31	2025-07-17 16:47:31
acb77f95-c29f-4675-80f2-b823cebc43b1	maintenance_ticket	21	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 16:50:17	2025-07-17 16:50:17
0b9dbc3c-f4ce-4395-a8b4-842df6802902	maintenance_ticket	22	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 16:53:27	2025-07-17 16:53:27
0fa94be2-c64f-4ba2-8d95-2f51f087ec26	maintenance_ticket	23	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 16:57:46	2025-07-17 16:57:46
73b5fe61-7517-4d87-b2de-ba98d8dc2034	maintenance_ticket	24	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 17:01:06	2025-07-17 17:01:06
079dd0d4-e110-49b3-8660-5e7ffea5bf99	maintenance_ticket	25	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 17:04:45	2025-07-17 17:04:45
28e8fd30-df43-455e-b65f-c3eca9d0e278	maintenance_ticket	26	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 17:12:41	2025-07-17 17:12:41
c51d7929-5ce5-41c9-8968-32214335955a	maintenance_ticket	27	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 18:07:40	2025-07-17 18:07:40
1bc40ea5-4b32-4cc4-9315-ad4811a642ff	maintenance_ticket	28	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 18:15:27	2025-07-17 18:15:27
12e96973-f99b-4c28-a8db-ad4499a2b46c	maintenance_ticket	29	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 18:20:56	2025-07-17 18:20:56
14f9f7ec-d163-4212-b0c5-b9940f649a46	maintenance_ticket	30	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 18:23:32	2025-07-17 18:23:32
0547b2ef-b01f-4c77-b5b6-86110f704476	maintenance_ticket	31	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 20:18:05	2025-07-17 20:18:05
c87d2b9e-9092-47c7-bb68-289e07d2321c	maintenance_ticket	32	created	creó ticket de mantenimiento 'Check-in de camión ABC-123'	\N	\N	\N	1	2	2025-07-17 20:26:52	2025-07-17 20:26:52
54962032-4269-4aca-a250-54ec2d68f6b9	maintenance_ticket	33	created	creó ticket de mantenimiento 'Check-in de camión 1234'	\N	\N	\N	1	1	2025-07-17 20:32:59	2025-07-17 20:32:59
6fa21420-916e-4a4c-a8dc-e480ebf501c1	maintenance_ticket	34	created	creó ticket de mantenimiento 'Eiife'	\N	\N	\N	1	2	2025-07-17 20:42:05	2025-07-17 20:42:05
f4578bf8-ddc5-479f-8318-3c3f7427c51a	maintenance_ticket	35	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-17 20:52:53	2025-07-17 20:52:53
05fb453b-62c0-4c8c-843d-b09f62b426fb	maintenance_ticket	36	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-17 20:54:04	2025-07-17 20:54:04
89384058-90a8-4959-b49f-f62b3573568e	maintenance_ticket	37	created	creó ticket de mantenimiento 'wao'	\N	\N	\N	1	1	2025-07-17 20:57:03	2025-07-17 20:57:03
114dce28-9e05-42bb-b32a-2d29492806d4	maintenance_ticket	38	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-17 20:59:02	2025-07-17 20:59:02
a9c573a6-dfea-41cf-8fbc-bd8a06bec5a3	maintenance_ticket	39	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-17 21:00:20	2025-07-17 21:00:20
bff45e27-bbd2-4abc-a1ba-7eeab2081d6f	maintenance_ticket	40	created	creó ticket de mantenimiento 'Eiife9999'	\N	\N	\N	1	1	2025-07-17 21:04:08	2025-07-17 21:04:08
0b149033-4f19-4df3-ad27-734d70138c01	maintenance_ticket	41	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-19 03:05:35	2025-07-19 03:05:35
ed610664-da73-4ddf-a433-e0e243d22c44	maintenance_ticket	42	created	creó ticket de mantenimiento 'Eiife'	\N	\N	\N	1	1	2025-07-19 03:10:05	2025-07-19 03:10:05
f55cdf60-c182-4800-ac45-b6aafc59774e	maintenance_ticket	43	created	creó ticket de mantenimiento 'Eiife9999'	\N	\N	\N	1	1	2025-07-19 03:22:19	2025-07-19 03:22:19
353f90f4-9e8a-4bec-adb3-fdd4ccddf3fc	maintenance_ticket	44	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-19 03:37:44	2025-07-19 03:37:44
275a46aa-1c9b-41b9-9ca3-35f6884041c0	maintenance_ticket	45	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-19 03:50:39	2025-07-19 03:50:39
e51b9bcf-fff9-4fe7-b08f-538172da8474	maintenance_ticket	46	created	creó ticket de mantenimiento 'qqq'	\N	\N	\N	1	1	2025-07-19 04:16:24	2025-07-19 04:16:24
ebcff672-166a-45a5-b7b3-5d2f6bf41acc	maintenance_ticket	47	created	creó ticket de mantenimiento 'qqq'	\N	\N	\N	1	1	2025-07-19 04:17:14	2025-07-19 04:17:14
6ee2d386-752c-49ff-9ef9-74d4ddca484f	maintenance_ticket	48	created	creó ticket de mantenimiento 'qqq'	\N	\N	\N	1	1	2025-07-19 04:21:31	2025-07-19 04:21:31
eaa16bf4-3cdd-46d3-a51a-5a29dfc34ee4	maintenance_ticket	49	created	creó ticket de mantenimiento 'Asd'	\N	\N	\N	1	1	2025-07-19 04:28:38	2025-07-19 04:28:38
546d82eb-1619-4c5f-8e19-7c95ed850eb4	maintenance_ticket	50	created	creó ticket de mantenimiento 'Oiuoiu'	\N	\N	\N	1	2	2025-07-19 04:42:06	2025-07-19 04:42:06
68724658-c6a0-45fc-b3e0-82981ee41b26	maintenance_ticket	51	created	creó ticket de mantenimiento 'Dkdkd'	\N	\N	\N	1	2	2025-07-19 04:44:21	2025-07-19 04:44:21
b151761d-478a-4512-8469-8747b76bb086	maintenance_ticket	52	created	creó ticket de mantenimiento 'Oiuoiu'	\N	\N	\N	1	2	2025-07-19 04:51:12	2025-07-19 04:51:12
b6dc95e4-b33f-4b4d-8196-d9e66f4b16b8	maintenance_ticket	53	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	2	2025-07-19 04:52:10	2025-07-19 04:52:10
3cf2f1e4-e228-45d0-bb29-cc7ee3b152eb	maintenance_ticket	54	created	creó ticket de mantenimiento 'Oiuoiu'	\N	\N	\N	1	2	2025-07-19 04:55:34	2025-07-19 04:55:34
8c578919-79b5-4d9a-9aad-92aa76dc9409	maintenance_ticket	55	created	creó ticket de mantenimiento 'uhh'	\N	\N	\N	1	1	2025-07-19 04:56:20	2025-07-19 04:56:20
e53b2f70-b4d3-469c-adff-41913cdec132	maintenance_ticket	56	created	creó ticket de mantenimiento 'Dkdkd'	\N	\N	\N	1	2	2025-07-19 05:01:54	2025-07-19 05:01:54
2bc11712-ac01-4909-bca8-aca093ca4dda	maintenance_ticket	57	created	creó ticket de mantenimiento 'uhh'	\N	\N	\N	1	2	2025-07-19 05:03:10	2025-07-19 05:03:10
488e8f7c-8e11-4a25-9ce5-dc921bf25088	maintenance_ticket	58	created	creó ticket de mantenimiento 'Eiife'	\N	\N	\N	1	1	2025-07-19 05:05:58	2025-07-19 05:05:58
e97b06ed-2278-4b8c-89de-9467b79381fe	maintenance_ticket	59	created	creó ticket de mantenimiento 'Eiife9999'	\N	\N	\N	1	1	2025-07-19 05:13:43	2025-07-19 05:13:43
6bf21ee9-9a0a-48ec-8922-fe5d6949dda5	maintenance_ticket	60	created	creó ticket de mantenimiento 'Dkdkd'	\N	\N	\N	1	2	2025-07-19 05:14:56	2025-07-19 05:14:56
f3f87c0a-b4d7-415b-a197-c8af9ec9c880	maintenance_ticket	61	created	creó ticket de mantenimiento 'Asd'	\N	\N	\N	1	1	2025-07-19 05:18:37	2025-07-19 05:18:37
42a33ecb-0ce6-4051-a766-31044edc880a	maintenance_ticket	62	created	creó ticket de mantenimiento 'Dkdkd'	\N	\N	\N	1	2	2025-07-19 05:22:04	2025-07-19 05:22:04
e3714019-4b7d-4951-bfdb-e0989f234b69	truck	10	created	creó camión 'nissan altima (333)'	\N	\N	\N	1	1	2025-07-19 05:43:13	2025-07-19 05:43:13
d78b9aef-6f8a-461a-96a7-f8cbc91a7832	maintenance_ticket	63	created	creó ticket de mantenimiento 'qqq'	\N	\N	\N	1	1	2025-07-19 05:43:36	2025-07-19 05:43:36
3673148d-e6ba-48fe-b9e7-f93d936c82f7	truck	11	created	creó camión 'Volvo FH16 (222)'	\N	\N	\N	1	1	2025-07-19 05:47:10	2025-07-19 05:47:10
793be2dd-2ffb-4cb5-aaf5-bd702445cbc8	maintenance_ticket	64	created	creó ticket de mantenimiento 'Eiife9999'	\N	\N	\N	1	1	2025-07-19 05:48:16	2025-07-19 05:48:16
2c7cb1d9-8a9a-4595-880e-fdcacc48a25f	maintenance_ticket	65	created	creó ticket de mantenimiento 'Eiife'	\N	\N	\N	1	1	2025-07-19 05:52:18	2025-07-19 05:52:18
84226ebf-91c9-423b-8e94-1774aa450bd2	maintenance_ticket	66	created	creó ticket de mantenimiento 'wow'	\N	\N	\N	1	1	2025-07-19 06:25:10	2025-07-19 06:25:10
6591c6a8-09da-41fc-b17e-305a663a17d7	maintenance_ticket	63	status_changed	Estado cambiado de 'check_in' a 'in_workshop'	{"status": "check_in"}	{"status": "in_workshop"}	\N	1	1	2025-07-24 23:57:53	2025-07-24 23:57:53
a65b4fae-765a-4a6a-8e59-909f33526c56	truck	13	created	creó camión 'volvo toro (1234567)'	\N	\N	\N	1	1	2025-07-24 23:58:43	2025-07-24 23:58:43
c642b90e-7184-4967-8d56-ca77bd2d4a95	maintenance_ticket	69	created	creó ticket de mantenimiento '253'	\N	\N	\N	1	1	2025-07-24 23:59:41	2025-07-24 23:59:41
d7d8cbfb-296b-4a37-8a2c-a7d28ae6f404	maintenance_ticket	69	status_changed	Estado cambiado de 'check_in' a 'check_out'	{"status": "check_in"}	{"status": "check_out"}	\N	1	1	2025-07-25 00:06:04	2025-07-25 00:06:04
3eee59d1-0b0d-466a-bd51-2cdbb34ed3d6	maintenance_ticket	69	status_changed	Estado cambiado de 'check_out' a 'final_review'	{"status": "check_out"}	{"status": "final_review"}	\N	1	1	2025-07-25 01:41:14	2025-07-25 01:41:14
fef0a2ed-c684-4a4f-9e27-a248f00ddfc3	truck	14	created	creó camión 'Volvo FH16 (222)'	\N	\N	\N	1	1	2025-08-01 19:35:57	2025-08-01 19:35:57
e4e53679-9595-47a8-9ca7-d2a9d9e94ac7	maintenance_ticket	70	created	creó ticket de mantenimiento 'djsof'	\N	\N	\N	1	1	2025-08-01 19:37:04	2025-08-01 19:37:04
aeb67da1-53e0-4079-b2af-598dcde09ff2	truck	15	created	creó camión 'Mitsubishi Canter Canter 18’  (PP535905)'	\N	\N	\N	1	1	2025-08-01 19:48:26	2025-08-01 19:48:26
de429db1-25d0-430d-a21a-a1c29d43d8aa	maintenance_ticket	71	created	creó ticket de mantenimiento 'Nuevo'	\N	\N	\N	1	1	2025-08-01 19:53:12	2025-08-01 19:53:12
a97baabc-0846-4cf2-a730-08310db8c88a	truck	16	created	creó camión 'Mitsubishi FA (L-481695)'	\N	\N	\N	1	1	2025-08-05 15:09:41	2025-08-05 15:09:41
4eb30453-35ab-4cb3-b4ec-2a514789f5f9	truck	17	created	creó camión 'Mitsubishi FA (L-481700)'	\N	\N	\N	1	1	2025-08-05 15:38:45	2025-08-05 15:38:45
7db6328b-ce42-4346-b6a7-43d43528dcc4	truck	18	created	creó camión 'Mitsubishi FA (L-483366)'	\N	\N	\N	1	1	2025-08-05 15:50:33	2025-08-05 15:50:33
a6da16b6-1ba8-4fbf-bc9e-4d73dfb4944b	truck	19	created	creó camión 'Mercedes-Benz Actros (222)'	\N	\N	\N	6	1	2025-08-06 08:17:23	2025-08-06 08:17:23
daca96b1-1a84-40dc-b41a-340603757c34	truck	20	created	creó camión 'ASHOK LEYLAND BOSS 914LE (L-521818 )'	\N	\N	\N	7	1	2025-08-07 18:17:02	2025-08-07 18:17:02
ebdcad22-2f8e-4176-8ebe-178345b0a8dc	maintenance_ticket	74	created	creó ticket de mantenimiento 'Check-in de camión L-521818 '	\N	\N	\N	6	1	2025-08-11 10:42:28	2025-08-11 10:42:28
\.


--
-- Data for Name: businesses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.businesses (id, name, inserted_at, updated_at) FROM stdin;
1	Spa Demo	2025-07-02 23:07:18	2025-07-02 23:07:18
2	Gaepell Consortium	2025-07-02 23:18:42	2025-07-02 23:18:42
3	Polimat	2025-07-05 00:19:31	2025-07-05 00:19:31
4	Test Business	2025-07-19 06:31:06	2025-07-19 06:31:06
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.companies (id, business_id, name, website, phone, email, address, city, state, country, postal_code, industry, size, description, status, inserted_at, updated_at) FROM stdin;
1	1	Dr. María García	https://drmariagarcia.com	+52 55 1234 5678	dr.garcia@clinica.com	Av. Insurgentes Sur 1234, Consultorio 5	CDMX	CDMX	México	03800	Cirugía Plástica	medium	Especialista en cirugía plástica y reconstructiva con más de 15 años de experiencia.	active	2025-07-02 23:07:19	2025-07-02 23:07:19
2	1	Dr. Carlos Rodríguez	https://drcarlosrodriguez.com	+52 55 9876 5432	dr.rodriguez@clinica.com	Av. Reforma 567, Piso 3	CDMX	CDMX	México	06500	Dermatología	medium	Dermatólogo especializado en medicina estética y tratamientos láser.	active	2025-07-02 23:07:19	2025-07-02 23:07:19
3	2	Furcar Manufacturing	https://furcar.com	+1-809-555-0200	contacto@furcar.com	Santiago, República Dominicana	\N	\N	\N	\N	Manufactura	\N	Fabricante de cajas para camiones	active	2025-07-02 23:20:43	2025-07-02 23:20:43
4	2	Logística Caribe	https://logisticacaribe.com	+1-809-555-0300	info@logisticacaribe.com	Puerto Plata, República Dominicana	\N	\N	\N	\N	Logística	\N	Empresa de transporte y logística	active	2025-07-02 23:20:43	2025-07-02 23:20:43
5	2	Constructora Dominicana	https://constructora.com	+1-809-555-0400	contacto@constructora.com	Santo Domingo, República Dominicana	\N	\N	\N	\N	Construcción	\N	Empresa de construcción y desarrollo	active	2025-07-02 23:20:43	2025-07-02 23:20:43
6	2	Agroindustria del Norte	https://agroindustria.com	+1-809-555-0500	info@agroindustria.com	La Vega, República Dominicana	\N	\N	\N	\N	Agroindustria	\N	Empresa agrícola y procesamiento	active	2025-07-02 23:20:43	2025-07-02 23:20:43
7	2	Furcar	https://furcar.com	+1-809-555-0200	contacto@furcar.com	Santiago, República Dominicana	\N	\N	\N	\N	Manufactura y Mantenimiento	\N	Empresa especializada en fabricación de cajas para camiones y servicios de mantenimiento	active	2025-07-02 23:45:52	2025-07-02 23:45:52
8	2	Blidomca	https://blidomca.com	+1-809-555-0300	info@blidomca.com	Santo Domingo, República Dominicana	\N	\N	\N	\N	Blindaje y Seguridad	\N	Empresa especializada en servicios de blindaje y protección vehicular	active	2025-07-02 23:45:52	2025-07-02 23:45:52
9	2	Grupo Gaepell	https://gaepell.com	+1-809-555-0100	info@gaepell.com	Santo Domingo, República Dominicana	\N	\N	\N	\N	Consorcio	\N	Consorcio dominicano especializado en manufactura y logística	active	2025-07-02 23:45:52	2025-07-02 23:45:52
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contacts (id, business_id, company_id, first_name, last_name, email, phone, mobile, job_title, department, address, city, state, country, postal_code, birth_date, notes, status, source, tags, inserted_at, updated_at, specialist_id, company_name) FROM stdin;
2	2	3	Carlos	Rodríguez	carlos.rodriguez@furcar.com	+1-809-555-0201	\N	Director de Operaciones	\N	\N	\N	\N	\N	\N	\N	\N	active	referral	{}	2025-07-02 23:20:43	2025-07-02 23:20:43	\N	\N
3	2	3	María	González	maria.gonzalez@furcar.com	+1-809-555-0202	\N	Gerente de Compras	\N	\N	\N	\N	\N	\N	\N	\N	active	website	{}	2025-07-02 23:20:43	2025-07-02 23:20:43	\N	\N
4	2	4	Roberto	Martínez	roberto.martinez@logisticacaribe.com	+1-809-555-0301	\N	CEO	\N	\N	\N	\N	\N	\N	\N	\N	active	event	{}	2025-07-02 23:20:43	2025-07-02 23:20:43	\N	\N
5	2	5	Ana	López	ana.lopez@constructora.com	+1-809-555-0401	\N	Directora de Proyectos	\N	\N	\N	\N	\N	\N	\N	\N	prospect	social_media	{}	2025-07-02 23:20:43	2025-07-02 23:20:43	\N	\N
6	2	6	José	Hernández	jose.hernandez@agroindustria.com	+1-809-555-0501	\N	Gerente de Logística	\N	\N	\N	\N	\N	\N	\N	\N	active	referral	{}	2025-07-02 23:20:43	2025-07-02 23:20:43	\N	\N
7	2	8	Roberto	Martínez	roberto.martinez@blidomca.com	+1-809-555-0301	\N	Director de Blindaje	\N	\N	\N	\N	\N	\N	\N	\N	active	event	{}	2025-07-02 23:45:52	2025-07-02 23:45:52	\N	\N
8	2	8	Ana	López	ana.lopez@blidomca.com	+1-809-555-0302	\N	Gerente de Instalaciones	\N	\N	\N	\N	\N	\N	\N	\N	active	referral	{}	2025-07-02 23:45:52	2025-07-02 23:45:52	\N	\N
9	2	9	José	Hernández	jose.hernandez@gaepell.com	+1-809-555-0101	\N	Director General	\N	\N	\N	\N	\N	\N	\N	\N	active	referral	{}	2025-07-02 23:45:52	2025-07-02 23:45:52	\N	\N
11	3	\N	Diego López	Cliente	diego.lopez@conferencias.com	+54 11 9999-0000	\N	Cliente	\N	\N	\N	\N	\N	\N	\N	Cliente convertido desde lead: Diego López	active	other	{}	2025-07-08 02:16:23	2025-07-08 02:16:23	\N	\N
24	1	\N	RAYMOND 	DE LOS SANTOS	RAYMONDEDUARDO@GMAIL.COM	8097697010	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	active	other	{}	2025-07-25 18:32:50	2025-07-25 18:35:39	\N	EXQUISITECES TERESA MATEO
\.


--
-- Data for Name: feedback_comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.feedback_comments (id, feedback_report_id, author, body, inserted_at, updated_at) FROM stdin;
\.


--
-- Data for Name: feedback_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.feedback_reports (id, reporter, description, severity, status, photos, inserted_at, updated_at) FROM stdin;
\.


--
-- Data for Name: leads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.leads (id, business_id, company_id, email, phone, company_name, source, status, priority, notes, inserted_at, updated_at, name, assigned_to, next_follow_up, conversion_date, user_id) FROM stdin;
6	2	\N	roberto.silva@empresa.com	+54 11 3333-4444	Empresa Ejecutiva	referral	qualified	high	Evaluando propuesta de blindaje	2025-07-06 22:31:14	2025-07-08 04:11:18	Roberto Silva	\N	2024-01-22 15:00:00	\N	\N
8	3	\N	diego.lopez@conferencias.com	+54 11 9999-0000	Conferencias Internacionales	event	qualified	high	Organizando conferencia para 500 personas	2025-07-06 22:31:14	2025-07-07 02:38:18	Diego López	\N	2024-01-28 13:00:00	\N	\N
5	2	\N	ana.martinez@seguridad.com	+54 11 1111-2222	Seguridad Total	website	contacted	medium	Interesada en blindaje para vehículos ejecutivos	2025-07-06 22:31:14	2025-07-07 23:08:00	Ana Martínez	\N	2024-01-18 11:00:00	\N	\N
7	3	\N	laura.fernandez@eventos.com	+54 11 7777-8888	Eventos Profesionales	social_media	contacted	medium	Interesada en servicios de eventos corporativos	2025-07-06 22:31:14	2025-07-07 23:08:37	Laura Fernández	\N	2024-01-16 09:00:00	\N	\N
\.


--
-- Data for Name: maintenance_ticket_checkouts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.maintenance_ticket_checkouts (id, maintenance_ticket_id, delivered_to_name, delivered_to_id_number, delivered_to_phone, delivered_at, photos, signature, notes, inserted_at, updated_at) FROM stdin;
\.


--
-- Data for Name: maintenance_tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.maintenance_tickets (id, truck_id, entry_date, mileage, fuel_level, visible_damage, damage_photos, responsible_signature, status, exit_date, exit_notes, inserted_at, updated_at, title, description, priority, business_id, specialist_id, color, signature_url, deliverer_name, document_type, document_number, deliverer_phone, deliverer_email, deliverer_address, company_name, "position", employee_number, authorization_type, special_conditions, entry_type, quotation_id, production_status, box_type, estimated_delivery) FROM stdin;
71	15	2025-07-31 15:51:00	100	empty	\N	{/uploads/ticket_71_1754078064489308517.jpg,/uploads/ticket_71_1754078064499665712.jpg}	\N	in_workshop	\N	\N	2025-08-01 19:53:12	2025-08-01 20:05:17	Nuevo	Entregador: Chichi | Doc: Licencia 00110228145 | Tel: 8092891818 | Email: gpp.jr@claro.net.do | Empresa: H Alimento | Cargo: Conductor | KM: 100 | Combustible: Vacío	medium	1	\N	#3b82f6	/uploads/signature_71_1754078064507373829.png	Chichi	licencia	00110228145	8092891818	gpp.jr@claro.net.do	4406 N.W 74 Ave	H Alimento	Conductor	\N	\N	\N	maintenance	\N	pending_quote	\N	\N
\.


--
-- Data for Name: material_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.material_categories (id, name, description, color, business_id, inserted_at, updated_at) FROM stdin;
1	Cartón	Diferentes tipos de cartón	#8B4513	1	2025-08-01 14:57:41	2025-08-01 14:57:41
2	Papel	Papeles especializados	#F5F5DC	1	2025-08-01 14:57:41	2025-08-01 14:57:41
3	Adhesivos	Pegamentos y adhesivos	#FFD700	1	2025-08-01 14:57:41	2025-08-01 14:57:41
4	Acabados	Materiales de acabado	#C0C0C0	1	2025-08-01 14:57:41	2025-08-01 14:57:41
\.


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.materials (id, name, description, unit, cost_per_unit, current_stock, min_stock, supplier, supplier_contact, lead_time_days, is_active, business_id, category_id, inserted_at, updated_at) FROM stdin;
1	Cartón Corrugado 3mm	Cartón corrugado de 3mm de grosor	m2	15.50	100.00	10.00	Proveedor Principal	\N	0	t	1	1	2025-08-01 14:57:41	2025-08-01 14:57:41
2	Cartón Corrugado 5mm	Cartón corrugado de 5mm de grosor	m2	22.00	100.00	10.00	Proveedor Principal	\N	0	t	1	1	2025-08-01 14:57:41	2025-08-01 14:57:41
3	Cartón Microcorrugado	Cartón microcorrugado fino	m2	12.00	100.00	10.00	Proveedor Principal	\N	0	t	1	1	2025-08-01 14:57:41	2025-08-01 14:57:41
4	Papel Kraft 80g	Papel kraft de 80 gramos	m2	8.50	100.00	10.00	Proveedor Principal	\N	0	t	1	2	2025-08-01 14:57:41	2025-08-01 14:57:41
5	Papel Couché 150g	Papel couché de 150 gramos	m2	18.00	100.00	10.00	Proveedor Principal	\N	0	t	1	2	2025-08-01 14:57:41	2025-08-01 14:57:41
6	Papel Metalizado	Papel metalizado premium	m2	35.00	100.00	10.00	Proveedor Principal	\N	0	t	1	2	2025-08-01 14:57:41	2025-08-01 14:57:41
7	Pegamento PVA	Pegamento PVA para cartón	litros	45.00	100.00	10.00	Proveedor Principal	\N	0	t	1	3	2025-08-01 14:57:41	2025-08-01 14:57:41
8	Cinta Doble Cara	Cinta adhesiva doble cara	metros	2.50	100.00	10.00	Proveedor Principal	\N	0	t	1	3	2025-08-01 14:57:41	2025-08-01 14:57:41
9	Barniz UV	Barniz UV para acabado	litros	120.00	100.00	10.00	Proveedor Principal	\N	0	t	1	4	2025-08-01 14:57:41	2025-08-01 14:57:41
10	Foil Dorado	Foil dorado para estampado	m2	85.00	100.00	10.00	Proveedor Principal	\N	0	t	1	4	2025-08-01 14:57:41	2025-08-01 14:57:41
\.


--
-- Data for Name: package_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.package_assignments (id, start_date, end_date, status, notes, package_id, contact_id, company_id, business_id, inserted_at, updated_at) FROM stdin;
\.


--
-- Data for Name: package_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.package_services (id, quantity, service_order, package_id, service_id, inserted_at, updated_at) FROM stdin;
1	2	1	1	4	2025-07-02 23:07:46	2025-07-02 23:07:46
2	1	2	1	5	2025-07-02 23:07:46	2025-07-02 23:07:46
3	1	3	1	8	2025-07-02 23:07:46	2025-07-02 23:07:46
4	4	1	2	4	2025-07-02 23:07:46	2025-07-02 23:07:46
5	2	2	2	5	2025-07-02 23:07:46	2025-07-02 23:07:46
6	2	3	2	6	2025-07-02 23:07:46	2025-07-02 23:07:46
7	2	4	2	8	2025-07-02 23:07:46	2025-07-02 23:07:46
8	2	5	2	9	2025-07-02 23:07:46	2025-07-02 23:07:46
9	2	1	3	1	2025-07-02 23:07:46	2025-07-02 23:07:46
10	1	2	3	3	2025-07-02 23:07:46	2025-07-02 23:07:46
\.


--
-- Data for Name: packages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.packages (id, name, description, total_price, discount_percentage, is_active, business_id, inserted_at, updated_at) FROM stdin;
1	Paquete Post-Cirugía Básico	Paquete básico de recuperación post-cirugía estética	280.00	15.00	t	1	2025-07-02 23:07:46	2025-07-02 23:07:46
2	Paquete Post-Cirugía Premium	Paquete completo de recuperación post-cirugía estética	450.00	20.00	t	1	2025-07-02 23:07:46	2025-07-02 23:07:46
3	Paquete Bienestar	Paquete de servicios de bienestar y relajación	180.00	10.00	t	1	2025-07-02 23:07:46	2025-07-02 23:07:46
\.


--
-- Data for Name: production_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.production_orders (id, client_name, truck_brand, truck_model, license_plate, box_type, specifications, estimated_delivery, status, business_id, specialist_id, workflow_id, workflow_state_id, notes, actual_delivery_date, total_cost, materials_used, quality_check_notes, customer_signature, photos, inserted_at, updated_at, contact_id) FROM stdin;
14	H Alimentos SRL	Mitsubishi	Canter 18’ 	PP535905	dry_box	dfs	2025-08-21	reception	1	\N	\N	\N	kfewle	\N	\N	\N	\N	\N	\N	2025-08-06 09:49:54	2025-08-06 09:50:25	\N
\.


--
-- Data for Name: quotation_options; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quotation_options (id, option_name, material_configuration, quality_level, production_cost, markup_percentage, final_price, delivery_time_days, is_recommended, quotation_id, inserted_at, updated_at) FROM stdin;
1	Opción Premium	\N	premium	2800.00	40.00	3920.00	5	f	1	2025-08-01 15:02:10	2025-08-01 15:02:10
2	Opción Estándar	\N	standard	2500.00	30.00	3250.00	7	t	1	2025-08-01 15:02:10	2025-08-01 15:02:10
3	Opción Económica	\N	economy	2000.00	20.00	2400.00	10	f	1	2025-08-01 15:02:10	2025-08-01 15:02:10
\.


--
-- Data for Name: quotations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quotations (id, quotation_number, client_name, client_email, client_phone, quantity, special_requirements, status, total_cost, markup_percentage, final_price, valid_until, business_id, user_id, inserted_at, updated_at) FROM stdin;
1	COT-202508-001	Empresa ABC	compras@empresaabc.com	+1 (555) 123-4567	100	Cajas para productos electrónicos con protección antiestática	draft	2500.00	30.00	3250.00	2025-08-31	1	1	2025-08-01 15:02:10	2025-08-01 15:02:10
2	COT-202508-002	H Alimentos SRL	\N	\N	1	0	draft	\N	30.00	\N	\N	1	6	2025-08-07 18:53:25	2025-08-07 18:53:25
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version, inserted_at) FROM stdin;
20250629004315	2025-07-02 22:44:37
20250629004325	2025-07-02 22:44:37
20250629012049	2025-07-02 22:44:37
20250629012054	2025-07-02 22:44:37
20250629012058	2025-07-02 22:44:37
20250629012103	2025-07-02 22:44:37
20250629044744	2025-07-02 22:44:37
20250629044749	2025-07-02 22:44:37
20250629044759	2025-07-02 22:44:37
20250629044810	2025-07-02 22:44:37
20250629044821	2025-07-02 22:44:37
20250629044910	2025-07-02 22:44:37
20250629054924	2025-07-02 22:44:37
20250629063737	2025-07-02 22:44:37
20250629071737	2025-07-02 22:44:37
20250629074527	2025-07-02 22:44:37
20250702212035	2025-07-02 22:44:37
20250702212039	2025-07-02 22:44:37
20250703120000	2025-07-02 23:30:09
20250703120100	2025-07-03 00:07:04
20250703120200	2025-07-03 00:08:10
20250703002637	2025-07-03 00:26:55
20250703041707	2025-07-03 04:18:44
20250703044244	2025-07-03 04:43:17
20250703052234	2025-07-03 05:23:06
20250703052237	2025-07-03 05:23:06
20250705000001	2025-07-05 00:47:53
20250705031015	2025-07-05 04:05:36
20250705031010	2025-07-05 04:19:31
20250705031046	2025-07-05 04:19:31
20250706003000	2025-07-06 00:30:22
20250706003046	2025-07-06 00:31:16
20250706055849	2025-07-06 05:59:04
20250705000002	2025-07-06 09:17:38
20250705000003	2025-07-06 09:19:57
20250705000004	2025-07-06 09:31:18
20250706094411	2025-07-06 09:44:34
20250707000000	2025-07-07 00:11:11
20250707000001	2025-07-07 01:09:24
20250713082931	2025-07-13 08:32:41
20250713205250	2025-07-13 20:53:31
20250719043922	2025-07-19 04:39:37
20250719061816	2025-07-19 06:18:35
20250721000000	2025-07-24 21:27:19
20250721000100	2025-07-24 21:27:19
20250725000000	2025-07-25 00:34:11
20250801050000	2025-08-01 14:49:36
20250801050001	2025-08-01 14:49:36
20250801050002	2025-08-01 14:57:29
20250801050003	2025-08-01 14:57:30
20250801190906	2025-08-01 19:09:33
20250805233853	2025-08-05 23:43:41
20250805235411	2025-08-05 23:58:47
20250806065351	2025-08-06 06:54:18
20250806074926	2025-08-06 07:50:06
20250807191600	2025-08-07 19:20:16
20250808150940	2025-08-08 15:16:59
\.


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.services (id, name, description, price, duration_minutes, service_type, category, is_active, business_id, inserted_at, updated_at) FROM stdin;
1	Masaje Relajante	Masaje terapéutico para relajación muscular y reducción del estrés	45.00	60	individual	masaje	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
2	Masaje Reductor	Masaje especializado para reducir grasa localizada y mejorar la circulación	55.00	60	individual	masaje	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
3	Masaje Deportivo	Masaje para deportistas, recuperación muscular y prevención de lesiones	50.00	60	individual	masaje	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
4	Masaje Post-Quirúrgico	Masaje especializado para recuperación post-cirugía estética	60.00	60	individual	masaje	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
5	Cámara Hiperbárica	Terapia de oxigenación hiperbárica para acelerar la recuperación	80.00	90	individual	terapia	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
6	Indiba	Terapia de radiofrecuencia para regeneración celular y drenaje linfático	70.00	45	individual	terapia	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
7	Consulta Psicológica Pre-Quirúrgica	Evaluación psicológica previa a cirugía estética	65.00	60	individual	psicologia	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
8	Consulta Psicológica Post-Quirúrgica	Seguimiento psicológico post-cirugía estética	65.00	60	individual	psicologia	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
9	Limpieza de Vendaje	Limpieza y cambio de vendajes post-quirúrgicos	35.00	30	individual	limpieza	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
10	Tratamiento Láser	Tratamiento láser para cicatrices y rejuvenecimiento	120.00	45	individual	laser	t	1	2025-07-02 23:07:19	2025-07-02 23:07:19
11	Mantenimiento Preventivo	Servicio de mantenimiento preventivo para flota de camiones	500.00	60	individual	limpieza	t	2	2025-07-02 23:23:21	2025-07-02 23:23:21
12	Reparación de Motor	Servicio de reparación y diagnóstico de motores	1500.00	60	individual	limpieza	t	2	2025-07-02 23:23:21	2025-07-02 23:23:21
13	Reparación de Sistema Eléctrico	Diagnóstico y reparación de sistemas eléctricos	800.00	60	individual	limpieza	t	2	2025-07-02 23:23:21	2025-07-02 23:23:21
14	Cambio de Aceite y Filtros	Servicio de cambio de aceite y filtros	200.00	60	individual	limpieza	t	2	2025-07-02 23:23:21	2025-07-02 23:23:21
15	Reparación de Frenos	Servicio de reparación y mantenimiento de frenos	600.00	60	individual	limpieza	t	2	2025-07-02 23:23:21	2025-07-02 23:23:21
\.


--
-- Data for Name: specialists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.specialists (id, first_name, last_name, email, phone, specialization, is_active, business_id, inserted_at, updated_at, status, availability) FROM stdin;
1	María	González	maria.gonzalez@bodhi.com	+1-555-0101	Masaje Terapéutico	t	1	2025-07-02 23:07:46	2025-07-02 23:07:46	active	\N
2	Ana	Rodríguez	ana.rodriguez@bodhi.com	+1-555-0102	Terapia Física	t	1	2025-07-02 23:07:46	2025-07-02 23:07:46	active	\N
3	Dr. Laura	Martínez	laura.martinez@bodhi.com	+1-555-0103	Psicología	t	1	2025-07-02 23:07:46	2025-07-02 23:07:46	active	\N
4	Carmen	López	carmen.lopez@bodhi.com	+1-555-0104	Enfermería	t	1	2025-07-02 23:07:46	2025-07-02 23:07:46	active	\N
5	Miguel	Santos	miguel.santos@gaepell.com	+1-809-555-0601	Mecánico	t	2	2025-07-02 23:22:30	2025-07-02 23:22:30	active	\N
6	Pedro	Ramírez	pedro.ramirez@gaepell.com	+1-809-555-0602	Eléctrico	t	2	2025-07-02 23:22:30	2025-07-02 23:22:30	active	\N
7	Luis	Fernández	luis.fernandez@gaepell.com	+1-809-555-0603	Técnico	t	2	2025-07-02 23:22:30	2025-07-02 23:22:30	active	\N
8	Especialista	Usuario	operaciones@eva.com	\N	Otra	f	1	2025-07-13 07:46:32	2025-07-13 07:46:32	active	\N
\.


--
-- Data for Name: symasoft_imports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.symasoft_imports (id, filename, file_path, content_hash, import_status, processed_at, error_message, business_id, user_id, inserted_at, updated_at) FROM stdin;
1	symasoft_import_1754075698530.csv	/Users/ricardorodriguez/Desktop/EVACRM/evaa_crm_gaepell/sample_data/symasoft_import_1754075698530.csv	51684D2461029C38A3AD7CF62ADBB484596B284C8600936876980C8BBB5170A3	failed	\N	Error al guardar archivo: enoent	1	1	2025-08-01 19:14:58	2025-08-01 19:14:58
2	symasoft_import_1754075802574.csv	/Users/ricardorodriguez/Desktop/EVACRM/evaa_crm_gaepell/sample_data/symasoft_import_1754075802574.csv	51684D2461029C38A3AD7CF62ADBB484596B284C8600936876980C8BBB5170A3	completed	2025-08-01 19:16:42	\N	1	1	2025-08-01 19:16:42	2025-08-01 19:16:42
3	symasoft_import_1754076014007.csv	/Users/ricardorodriguez/Desktop/EVACRM/evaa_crm_gaepell/sample_data/symasoft_import_1754076014007.csv	51684D2461029C38A3AD7CF62ADBB484596B284C8600936876980C8BBB5170A3	completed	2025-08-01 19:20:14	\N	1	1	2025-08-01 19:20:14	2025-08-01 19:20:14
\.


--
-- Data for Name: truck_models; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.truck_models (id, brand, model, year, capacity, fuel_type, dimensions, weight, engine, transmission, usage_count, last_used_at, business_id, inserted_at, updated_at) FROM stdin;
1	Mitsubishi	Canter 18’ 	2025	\N	\N	\N	\N	\N	\N	1	2025-08-01 19:48:26	1	2025-08-06 00:09:31	2025-08-06 00:09:31
2	Mitsubishi	FA	2024	\N	\N	\N	\N	\N	\N	3	2025-08-06 00:09:31	1	2025-08-06 00:09:31	2025-08-06 00:09:31
3	ASHOK LEYLAND	BOSS 914LE	2024	\N	\N	\N	\N	\N	\N	1	2025-08-07 19:03:12	1	2025-08-07 19:03:12	2025-08-07 19:03:12
\.


--
-- Data for Name: truck_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.truck_notes (id, content, note_type, truck_id, maintenance_ticket_id, production_order_id, user_id, business_id, inserted_at, updated_at) FROM stdin;
\.


--
-- Data for Name: truck_photos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.truck_photos (id, photo_path, description, photo_type, truck_id, maintenance_ticket_id, user_id, uploaded_at, inserted_at, updated_at) FROM stdin;
3	/uploads/truck_20_photo_1754662608135432419_424.JPG	\N	general	20	\N	6	2025-08-08 14:16:48	2025-08-08 14:16:48	2025-08-08 14:16:48
2	/uploads/truck_20_photo_1754662549474234654_584.JPG	Techo Roto	general	20	\N	6	2025-08-08 14:15:49	2025-08-08 14:15:49	2025-08-08 14:20:05
4	/uploads/truck_18_photo_1754668727095162298_791.JPG	test	general	18	\N	6	2025-08-08 15:58:47	2025-08-08 15:58:47	2025-08-08 15:58:47
\.


--
-- Data for Name: trucks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trucks (id, brand, model, license_plate, chassis_number, vin, color, year, owner, general_notes, inserted_at, updated_at, capacity, fuel_type, status, business_id, profile_photo, ficha, kilometraje) FROM stdin;
15	Mitsubishi	Canter 18’ 	PP535905	\N	\N	\N	2025	H Alimentos SRL	Camión Nuevo para hacer plataforma según cotización  #	2025-08-01 19:48:26	2025-08-01 20:00:53	\N	\N	active	1	\N	\N	0
17	Mitsubishi	FA	L-481700	\N	\N	\N	2024	Induveca	Garantías:\n3 juegos de tornillos y su goma al sobrechasis\n\nFacturar:\n-Cotizacion 1245, solicitud de serv #10524685,  # pedido 4500411957	2025-08-05 15:38:45	2025-08-05 15:41:13	\N	\N	active	1	\N	FLR-1659-24	0
20	ASHOK LEYLAND	BOSS 914LE	L-521818 	\N	\N	\N	2024	CERVECERIA PUNTA CANA	\N	2025-08-07 18:17:02	2025-08-07 18:17:02	\N	\N	active	1	\N	\N	0
16	Mitsubishi	FA	L-481695	MEC0423PDRP065717	\N	\N	2024	Induveca	Garantías:\n-placas y tornillos al panel\n-patas tramos\n-colocacion de 3 juegos de tornillos al frente y goma al sobrechasis\n\nFacturar:\n-2 cajas esquineros superiores\n-Defenza perfil 4x4 1/4''\n	2025-08-05 15:09:41	2025-08-08 15:41:28	\N	\N	active	1	\N	FCO-1649-24	27712
18	Mitsubishi	FA	L-483366	MEC0423PERP066241	\N	\N	2024	Induveca	Cotizar:\n-Faja trasera inferior\n-Faja lateral inferior \n-Esquinero lateral posterior\n-Rellenar hueco accidente panel lateral pasajero\n-Cambio defensa perfil 4x4 1/4''	2025-08-05 15:50:33	2025-08-08 15:42:11	\N	\N	active	1	\N	FAZ-1673-24	0
22	MITSUBISHI	FJ	L-480745	1321231321321	\N	\N	2024	INDUVECA (PARMALAT)	\N	2025-08-08 16:22:01	2025-08-08 16:22:01	\N	\N	active	1	\N	FPP-1644-24	0
23	MITSUBISHI	FA	L-481697	MEC0423PDRP065733	\N	\N	2024	INDUVECA	\N	2025-08-08 16:27:02	2025-08-08 16:27:02	\N	\N	active	1	\N	FOC-1651-24	0
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, business_id, email, password_hash, role, inserted_at, updated_at, company_id, specialist_id) FROM stdin;
1	1	admin@eva.com	$2b$12$Y77Z/VrCrPYIUXGVXkoUw.1DFAk3Lec7OAlR9NS94JgTt502i1oVq	admin	2025-07-02 23:07:19	2025-07-02 23:07:19	\N	\N
6	1	getpovify@gmail.com	$2b$12$mM/91aoN.h/RBWGSPikeze0lXUVinSNeqRNz2PxeerjmZMVEBiUcK	admin	2025-07-25 03:31:22	2025-07-25 03:32:00	\N	\N
7	1	gpellicce@gmail.com	$2b$12$P7pcYGBY22eaXvHf/1xYN.Fy5HpmGgioHDEWiKtF9IMp/iHDETNvW	admin	2025-07-25 03:32:56	2025-07-25 03:32:56	\N	\N
\.


--
-- Data for Name: workflow_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_assignments (id, workflow_id, assignable_type, assignable_id, current_state_id, business_id, inserted_at, updated_at) FROM stdin;
4	14	lead	4	146	1	2025-07-07 02:11:00	2025-07-07 02:11:00
5	15	lead	5	154	2	2025-07-07 02:11:53	2025-07-07 02:11:53
6	16	lead	7	154	3	2025-07-07 02:11:53	2025-07-07 02:11:53
8	15	lead	6	156	2	2025-07-07 02:11:53	2025-07-07 02:11:53
7	16	lead	8	156	3	2025-07-07 02:11:53	2025-07-07 02:38:18
2	14	lead	3	143	1	2025-07-07 02:11:00	2025-07-07 04:20:48
1	14	lead	1	143	1	2025-07-07 01:09:30	2025-07-07 19:58:39
3	14	lead	2	144	1	2025-07-07 02:11:00	2025-07-07 19:59:14
\.


--
-- Data for Name: workflow_state_changes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_state_changes (id, workflow_assignment_id, from_state_id, to_state_id, changed_by_id, notes, metadata, inserted_at, updated_at) FROM stdin;
1	1	142	143	1	Prueba de sincronización	{}	2025-07-07 01:22:00	2025-07-07 01:22:00
2	2	143	144	1	\N	{}	2025-07-07 02:27:22	2025-07-07 02:27:22
3	7	155	156	1	\N	{}	2025-07-07 02:38:18	2025-07-07 02:38:18
4	1	143	144	1	Drag and drop test	{}	2025-07-07 03:09:15	2025-07-07 03:09:15
5	3	144	146	1	Drag and drop test	{}	2025-07-07 03:09:15	2025-07-07 03:09:15
6	2	144	143	1	Estado cambiado desde prospectos	{}	2025-07-07 04:20:25	2025-07-07 04:20:25
7	2	143	144	1	Estado cambiado desde prospectos	{}	2025-07-07 04:20:46	2025-07-07 04:20:46
8	2	144	143	1	Estado cambiado desde prospectos	{}	2025-07-07 04:20:48	2025-07-07 04:20:48
9	1	144	143	1	Estado cambiado desde prospectos	{}	2025-07-07 19:58:39	2025-07-07 19:58:39
10	3	146	144	1	Estado cambiado desde prospectos	{}	2025-07-07 19:59:14	2025-07-07 19:59:14
\.


--
-- Data for Name: workflow_states; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_states (id, name, label, description, order_index, color, icon, workflow_id, is_final, is_initial, inserted_at, updated_at) FROM stdin;
1	check_in	Check In	\N	1	#10B981	check-circle	1	f	t	2025-07-05 00:50:02	2025-07-05 00:50:02
2	in_workshop	En Taller/Reparación	\N	2	#3B82F6	wrench	1	f	f	2025-07-05 00:50:02	2025-07-05 00:50:02
3	final_review	Revisión Final	\N	3	#8B5CF6	clipboard-check	1	f	f	2025-07-05 00:50:02	2025-07-05 00:50:02
4	car_wash	Car Wash	\N	4	#06B6D4	droplets	1	f	f	2025-07-05 00:50:02	2025-07-05 00:50:02
5	check_out	Check Out	\N	5	#059669	check-square	1	t	f	2025-07-05 00:50:02	2025-07-05 00:50:02
142	new	Nuevo Lead	\N	1	#6B7280	\N	14	f	t	2025-07-06 22:40:32	2025-07-06 22:40:32
148	new	Nuevo Lead	\N	1	#6B7280	\N	15	f	t	2025-07-06 22:40:32	2025-07-06 22:40:32
154	new	Nuevo Lead	\N	1	#6B7280	\N	16	f	t	2025-07-06 22:40:32	2025-07-06 22:40:32
144	qualified	Calificado	\N	3	#3B82F6	\N	14	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
146	converted	Convertido	\N	4	#10B981	\N	14	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
150	qualified	Calificado	\N	3	#3B82F6	\N	15	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
152	converted	Convertido	\N	4	#10B981	\N	15	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
156	qualified	Calificado	\N	3	#3B82F6	\N	16	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
158	converted	Convertido	\N	4	#10B981	\N	16	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
136	new_order	Nueva Orden	\N	1	#6B7280	\N	19	f	f	2025-07-06 05:44:34	2025-07-06 05:44:34
137	reception	Recepción	\N	2	#F59E0B	\N	19	f	f	2025-07-06 05:44:34	2025-07-06 05:44:34
138	assembly	Ensamblaje	\N	3	#3B82F6	\N	19	f	f	2025-07-06 05:44:34	2025-07-06 05:44:34
139	mounting	Montaje	\N	4	#8B5CF6	\N	19	f	f	2025-07-06 05:44:34	2025-07-06 05:44:34
140	final_check	Final Check	\N	5	#10B981	\N	19	f	f	2025-07-06 05:44:34	2025-07-06 05:44:34
141	check_out	Check Out	\N	6	#059669	\N	19	f	f	2025-07-06 05:44:34	2025-07-06 05:44:34
80	assembly	Ensamblaje	\N	3	#3B82F6	\N	17	f	f	2025-07-05 20:30:22	2025-07-05 20:30:22
83	completed	Completado	\N	6	#059669	\N	17	f	f	2025-07-05 20:30:22	2025-07-05 20:30:22
143	contacted	Contactado	\N	2	#F59E0B	\N	14	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
147	lost	Perdido	\N	5	#EF4444	\N	14	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
149	contacted	Contactado	\N	2	#F59E0B	\N	15	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
153	lost	Perdido	\N	5	#EF4444	\N	15	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
155	contacted	Contactado	\N	2	#F59E0B	\N	16	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
159	lost	Perdido	\N	5	#EF4444	\N	16	f	f	2025-07-06 22:40:32	2025-07-06 22:40:32
116	completed	Completado	\N	5	#10B981	\N	20	f	f	2025-07-05 20:31:17	2025-07-05 20:31:17
117	cancelled	Cancelado	\N	6	#EF4444	\N	20	f	f	2025-07-05 20:31:17	2025-07-05 20:31:17
\.


--
-- Data for Name: workflow_transitions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_transitions (id, from_state_id, to_state_id, workflow_id, label, color, requires_approval, inserted_at, updated_at) FROM stdin;
1	1	2	1	Avanzar a En Taller/Reparación	#3B82F6	f	2025-07-05 00:50:02	2025-07-05 00:50:02
2	2	3	1	Avanzar a Revisión Final	#8B5CF6	f	2025-07-05 00:50:02	2025-07-05 00:50:02
3	3	4	1	Avanzar a Car Wash	#06B6D4	f	2025-07-05 00:50:02	2025-07-05 00:50:02
4	4	5	1	Avanzar a Check Out	#059669	f	2025-07-05 00:50:02	2025-07-05 00:50:02
20	142	143	14	Avanzar a Contactado	#F59E0B	f	2025-07-07 01:21:52	2025-07-07 01:21:52
21	143	144	14	Avanzar a Calificado	#3B82F6	f	2025-07-07 01:21:52	2025-07-07 01:21:52
22	144	146	14	Avanzar a Convertido	#10B981	f	2025-07-07 01:21:52	2025-07-07 01:21:52
23	146	147	14	Avanzar a Perdido	#EF4444	f	2025-07-07 01:21:52	2025-07-07 01:21:52
24	147	142	14	Reactivar lead	#6B7280	f	2025-07-07 01:21:52	2025-07-07 01:21:52
25	148	149	15	Avanzar a Contactado	#F59E0B	f	2025-07-07 01:21:52	2025-07-07 01:21:52
26	149	150	15	Avanzar a Calificado	#3B82F6	f	2025-07-07 01:21:52	2025-07-07 01:21:52
27	150	152	15	Avanzar a Convertido	#10B981	f	2025-07-07 01:21:52	2025-07-07 01:21:52
28	152	153	15	Avanzar a Perdido	#EF4444	f	2025-07-07 01:21:52	2025-07-07 01:21:52
29	153	148	15	Reactivar lead	#6B7280	f	2025-07-07 01:21:52	2025-07-07 01:21:52
30	154	155	16	Avanzar a Contactado	#F59E0B	f	2025-07-07 01:21:52	2025-07-07 01:21:52
31	155	156	16	Avanzar a Calificado	#3B82F6	f	2025-07-07 01:21:52	2025-07-07 01:21:52
32	156	158	16	Avanzar a Convertido	#10B981	f	2025-07-07 01:21:52	2025-07-07 01:21:52
33	158	159	16	Avanzar a Perdido	#EF4444	f	2025-07-07 01:21:52	2025-07-07 01:21:52
34	159	154	16	Reactivar lead	#6B7280	f	2025-07-07 01:21:52	2025-07-07 01:21:52
35	144	143	14	qualified -> contacted	gray	f	2025-07-07 04:10:38	2025-07-07 04:10:38
36	146	144	14	converted -> qualified	gray	f	2025-07-07 04:10:38	2025-07-07 04:10:38
37	146	143	14	converted -> contacted	gray	f	2025-07-07 04:10:38	2025-07-07 04:10:38
\.


--
-- Data for Name: workflows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflows (id, name, description, workflow_type, business_id, is_active, color, inserted_at, updated_at) FROM stdin;
1	Mantenimiento Furcar	Flujo de mantenimiento de camiones en Furcar	maintenance	1	t	#F59E0B	2025-07-05 00:50:02	2025-07-05 00:50:02
14	Leads Pipeline	Workflow para gestión de leads desde captura hasta conversión	leads	1	t	#3B82F6	2025-07-05 00:19:31	2025-07-05 00:19:31
15	Leads Pipeline	Workflow para gestión de leads desde captura hasta conversión	leads	2	t	#3B82F6	2025-07-05 00:19:31	2025-07-05 00:19:31
16	Leads Pipeline	Workflow para gestión de leads desde captura hasta conversión	leads	3	t	#3B82F6	2025-07-05 00:19:31	2025-07-05 00:19:31
17	Producción de Blindaje	Workflow para procesos de blindaje y protección vehicular	production	2	t	#3B82F6	2025-07-05 20:30:22	2025-07-05 20:30:22
19	Producción de Cajas	Workflow para fabricación de cajas para camiones	production	1	t	#3B82F6	2025-07-05 20:31:17	2025-07-05 20:31:17
20	Eventos de Polimat	Workflow para gestión de eventos y actividades especiales	events	3	t	#3B82F6	2025-07-05 20:31:17	2025-07-05 20:31:17
\.


--
-- Name: activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activities_id_seq', 73, true);


--
-- Name: businesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.businesses_id_seq', 4, true);


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.companies_id_seq', 9, true);


--
-- Name: contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contacts_id_seq', 24, true);


--
-- Name: feedback_comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.feedback_comments_id_seq', 5, true);


--
-- Name: feedback_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.feedback_reports_id_seq', 2, true);


--
-- Name: leads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.leads_id_seq', 12, true);


--
-- Name: maintenance_ticket_checkouts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.maintenance_ticket_checkouts_id_seq', 4, true);


--
-- Name: maintenance_tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.maintenance_tickets_id_seq', 74, true);


--
-- Name: material_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_categories_id_seq', 4, true);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.materials_id_seq', 10, true);


--
-- Name: package_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.package_assignments_id_seq', 1, false);


--
-- Name: package_services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.package_services_id_seq', 10, true);


--
-- Name: packages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.packages_id_seq', 3, true);


--
-- Name: production_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.production_orders_id_seq', 14, true);


--
-- Name: quotation_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quotation_options_id_seq', 3, true);


--
-- Name: quotations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quotations_id_seq', 2, true);


--
-- Name: services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.services_id_seq', 15, true);


--
-- Name: specialists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.specialists_id_seq', 8, true);


--
-- Name: symasoft_imports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.symasoft_imports_id_seq', 3, true);


--
-- Name: truck_models_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.truck_models_id_seq', 3, true);


--
-- Name: truck_notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.truck_notes_id_seq', 1, false);


--
-- Name: truck_photos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.truck_photos_id_seq', 4, true);


--
-- Name: trucks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.trucks_id_seq', 23, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 7, true);


--
-- Name: workflow_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_assignments_id_seq', 8, true);


--
-- Name: workflow_state_changes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_state_changes_id_seq', 10, true);


--
-- Name: workflow_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_states_id_seq', 159, true);


--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_transitions_id_seq', 37, true);


--
-- Name: workflows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflows_id_seq', 20, true);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: businesses businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: feedback_comments feedback_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_comments
    ADD CONSTRAINT feedback_comments_pkey PRIMARY KEY (id);


--
-- Name: feedback_reports feedback_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_reports
    ADD CONSTRAINT feedback_reports_pkey PRIMARY KEY (id);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: maintenance_ticket_checkouts maintenance_ticket_checkouts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_ticket_checkouts
    ADD CONSTRAINT maintenance_ticket_checkouts_pkey PRIMARY KEY (id);


--
-- Name: maintenance_tickets maintenance_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_pkey PRIMARY KEY (id);


--
-- Name: material_categories material_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_categories
    ADD CONSTRAINT material_categories_pkey PRIMARY KEY (id);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: package_assignments package_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_pkey PRIMARY KEY (id);


--
-- Name: package_services package_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_pkey PRIMARY KEY (id);


--
-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: production_orders production_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_pkey PRIMARY KEY (id);


--
-- Name: quotation_options quotation_options_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quotation_options
    ADD CONSTRAINT quotation_options_pkey PRIMARY KEY (id);


--
-- Name: quotations quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: specialists specialists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_pkey PRIMARY KEY (id);


--
-- Name: symasoft_imports symasoft_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symasoft_imports
    ADD CONSTRAINT symasoft_imports_pkey PRIMARY KEY (id);


--
-- Name: truck_models truck_models_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_models
    ADD CONSTRAINT truck_models_pkey PRIMARY KEY (id);


--
-- Name: truck_notes truck_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_pkey PRIMARY KEY (id);


--
-- Name: truck_photos truck_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_pkey PRIMARY KEY (id);


--
-- Name: trucks trucks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trucks
    ADD CONSTRAINT trucks_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: workflow_assignments workflow_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_pkey PRIMARY KEY (id);


--
-- Name: workflow_state_changes workflow_state_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_pkey PRIMARY KEY (id);


--
-- Name: workflow_states workflow_states_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_states
    ADD CONSTRAINT workflow_states_pkey PRIMARY KEY (id);


--
-- Name: workflow_transitions workflow_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_pkey PRIMARY KEY (id);


--
-- Name: workflows workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: activities_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_business_id_index ON public.activities USING btree (business_id);


--
-- Name: activities_company_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_company_id_index ON public.activities USING btree (company_id);


--
-- Name: activities_contact_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_contact_id_index ON public.activities USING btree (contact_id);


--
-- Name: activities_due_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_due_date_index ON public.activities USING btree (due_date);


--
-- Name: activities_is_package_service_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_is_package_service_index ON public.activities USING btree (is_package_service);


--
-- Name: activities_lead_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_lead_id_index ON public.activities USING btree (lead_id);


--
-- Name: activities_package_assignment_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_package_assignment_id_index ON public.activities USING btree (package_assignment_id);


--
-- Name: activities_service_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_service_id_index ON public.activities USING btree (service_id);


--
-- Name: activities_specialist_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_specialist_id_index ON public.activities USING btree (specialist_id);


--
-- Name: activities_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_status_index ON public.activities USING btree (status);


--
-- Name: activities_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_type_index ON public.activities USING btree (type);


--
-- Name: activities_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activities_user_id_index ON public.activities USING btree (user_id);


--
-- Name: activity_logs_action_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_logs_action_index ON public.activity_logs USING btree (action);


--
-- Name: activity_logs_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_logs_business_id_index ON public.activity_logs USING btree (business_id);


--
-- Name: activity_logs_entity_type_entity_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_logs_entity_type_entity_id_index ON public.activity_logs USING btree (entity_type, entity_id);


--
-- Name: activity_logs_inserted_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_logs_inserted_at_index ON public.activity_logs USING btree (inserted_at);


--
-- Name: activity_logs_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_logs_user_id_index ON public.activity_logs USING btree (user_id);


--
-- Name: businesses_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX businesses_name_index ON public.businesses USING btree (name);


--
-- Name: companies_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX companies_business_id_index ON public.companies USING btree (business_id);


--
-- Name: companies_business_id_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX companies_business_id_name_index ON public.companies USING btree (business_id, name);


--
-- Name: companies_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX companies_name_index ON public.companies USING btree (name);


--
-- Name: companies_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX companies_status_index ON public.companies USING btree (status);


--
-- Name: contacts_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contacts_business_id_index ON public.contacts USING btree (business_id);


--
-- Name: contacts_company_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contacts_company_id_index ON public.contacts USING btree (company_id);


--
-- Name: contacts_email_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contacts_email_index ON public.contacts USING btree (email);


--
-- Name: contacts_first_name_last_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contacts_first_name_last_name_index ON public.contacts USING btree (first_name, last_name);


--
-- Name: contacts_specialist_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contacts_specialist_id_index ON public.contacts USING btree (specialist_id);


--
-- Name: contacts_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contacts_status_index ON public.contacts USING btree (status);


--
-- Name: feedback_comments_feedback_report_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX feedback_comments_feedback_report_id_index ON public.feedback_comments USING btree (feedback_report_id);


--
-- Name: leads_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX leads_business_id_index ON public.leads USING btree (business_id);


--
-- Name: leads_company_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX leads_company_id_index ON public.leads USING btree (company_id);


--
-- Name: leads_priority_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX leads_priority_index ON public.leads USING btree (priority);


--
-- Name: leads_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX leads_status_index ON public.leads USING btree (status);


--
-- Name: maintenance_ticket_checkouts_maintenance_ticket_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX maintenance_ticket_checkouts_maintenance_ticket_id_index ON public.maintenance_ticket_checkouts USING btree (maintenance_ticket_id);


--
-- Name: maintenance_tickets_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX maintenance_tickets_business_id_index ON public.maintenance_tickets USING btree (business_id);


--
-- Name: maintenance_tickets_specialist_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX maintenance_tickets_specialist_id_index ON public.maintenance_tickets USING btree (specialist_id);


--
-- Name: maintenance_tickets_truck_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX maintenance_tickets_truck_id_index ON public.maintenance_tickets USING btree (truck_id);


--
-- Name: material_categories_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX material_categories_business_id_index ON public.material_categories USING btree (business_id);


--
-- Name: material_categories_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX material_categories_name_index ON public.material_categories USING btree (name);


--
-- Name: materials_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX materials_business_id_index ON public.materials USING btree (business_id);


--
-- Name: materials_category_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX materials_category_id_index ON public.materials USING btree (category_id);


--
-- Name: materials_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX materials_is_active_index ON public.materials USING btree (is_active);


--
-- Name: materials_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX materials_name_index ON public.materials USING btree (name);


--
-- Name: materials_supplier_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX materials_supplier_index ON public.materials USING btree (supplier);


--
-- Name: package_assignments_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX package_assignments_business_id_index ON public.package_assignments USING btree (business_id);


--
-- Name: package_assignments_company_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX package_assignments_company_id_index ON public.package_assignments USING btree (company_id);


--
-- Name: package_assignments_contact_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX package_assignments_contact_id_index ON public.package_assignments USING btree (contact_id);


--
-- Name: package_assignments_package_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX package_assignments_package_id_index ON public.package_assignments USING btree (package_id);


--
-- Name: package_assignments_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX package_assignments_status_index ON public.package_assignments USING btree (status);


--
-- Name: package_services_package_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX package_services_package_id_index ON public.package_services USING btree (package_id);


--
-- Name: package_services_package_id_service_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX package_services_package_id_service_id_index ON public.package_services USING btree (package_id, service_id);


--
-- Name: package_services_service_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX package_services_service_id_index ON public.package_services USING btree (service_id);


--
-- Name: packages_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX packages_business_id_index ON public.packages USING btree (business_id);


--
-- Name: packages_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX packages_is_active_index ON public.packages USING btree (is_active);


--
-- Name: production_orders_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX production_orders_business_id_index ON public.production_orders USING btree (business_id);


--
-- Name: production_orders_contact_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX production_orders_contact_id_index ON public.production_orders USING btree (contact_id);


--
-- Name: production_orders_specialist_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX production_orders_specialist_id_index ON public.production_orders USING btree (specialist_id);


--
-- Name: production_orders_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX production_orders_status_index ON public.production_orders USING btree (status);


--
-- Name: production_orders_workflow_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX production_orders_workflow_id_index ON public.production_orders USING btree (workflow_id);


--
-- Name: production_orders_workflow_state_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX production_orders_workflow_state_id_index ON public.production_orders USING btree (workflow_state_id);


--
-- Name: quotation_options_is_recommended_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX quotation_options_is_recommended_index ON public.quotation_options USING btree (is_recommended);


--
-- Name: quotation_options_quality_level_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX quotation_options_quality_level_index ON public.quotation_options USING btree (quality_level);


--
-- Name: quotation_options_quotation_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX quotation_options_quotation_id_index ON public.quotation_options USING btree (quotation_id);


--
-- Name: quotations_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX quotations_business_id_index ON public.quotations USING btree (business_id);


--
-- Name: quotations_client_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX quotations_client_name_index ON public.quotations USING btree (client_name);


--
-- Name: quotations_quotation_number_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX quotations_quotation_number_index ON public.quotations USING btree (quotation_number);


--
-- Name: quotations_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX quotations_status_index ON public.quotations USING btree (status);


--
-- Name: quotations_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX quotations_user_id_index ON public.quotations USING btree (user_id);


--
-- Name: services_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX services_business_id_index ON public.services USING btree (business_id);


--
-- Name: services_category_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX services_category_index ON public.services USING btree (category);


--
-- Name: services_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX services_is_active_index ON public.services USING btree (is_active);


--
-- Name: services_service_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX services_service_type_index ON public.services USING btree (service_type);


--
-- Name: specialists_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX specialists_business_id_index ON public.specialists USING btree (business_id);


--
-- Name: specialists_email_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX specialists_email_business_id_index ON public.specialists USING btree (email, business_id);


--
-- Name: specialists_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX specialists_is_active_index ON public.specialists USING btree (is_active);


--
-- Name: specialists_specialization_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX specialists_specialization_index ON public.specialists USING btree (specialization);


--
-- Name: specialists_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX specialists_status_index ON public.specialists USING btree (status);


--
-- Name: symasoft_imports_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX symasoft_imports_business_id_index ON public.symasoft_imports USING btree (business_id);


--
-- Name: symasoft_imports_content_hash_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX symasoft_imports_content_hash_index ON public.symasoft_imports USING btree (content_hash);


--
-- Name: symasoft_imports_import_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX symasoft_imports_import_status_index ON public.symasoft_imports USING btree (import_status);


--
-- Name: symasoft_imports_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX symasoft_imports_user_id_index ON public.symasoft_imports USING btree (user_id);


--
-- Name: truck_models_brand_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_models_brand_index ON public.truck_models USING btree (brand);


--
-- Name: truck_models_brand_model_year_business_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX truck_models_brand_model_year_business_index ON public.truck_models USING btree (brand, model, year, business_id);


--
-- Name: truck_models_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_models_business_id_index ON public.truck_models USING btree (business_id);


--
-- Name: truck_models_last_used_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_models_last_used_at_index ON public.truck_models USING btree (last_used_at);


--
-- Name: truck_models_model_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_models_model_index ON public.truck_models USING btree (model);


--
-- Name: truck_models_usage_count_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_models_usage_count_index ON public.truck_models USING btree (usage_count);


--
-- Name: truck_notes_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_notes_business_id_index ON public.truck_notes USING btree (business_id);


--
-- Name: truck_notes_inserted_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_notes_inserted_at_index ON public.truck_notes USING btree (inserted_at);


--
-- Name: truck_notes_maintenance_ticket_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_notes_maintenance_ticket_id_index ON public.truck_notes USING btree (maintenance_ticket_id);


--
-- Name: truck_notes_production_order_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_notes_production_order_id_index ON public.truck_notes USING btree (production_order_id);


--
-- Name: truck_notes_truck_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_notes_truck_id_index ON public.truck_notes USING btree (truck_id);


--
-- Name: truck_notes_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_notes_user_id_index ON public.truck_notes USING btree (user_id);


--
-- Name: truck_photos_maintenance_ticket_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_photos_maintenance_ticket_id_index ON public.truck_photos USING btree (maintenance_ticket_id);


--
-- Name: truck_photos_photo_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_photos_photo_type_index ON public.truck_photos USING btree (photo_type);


--
-- Name: truck_photos_truck_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_photos_truck_id_index ON public.truck_photos USING btree (truck_id);


--
-- Name: truck_photos_uploaded_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_photos_uploaded_at_index ON public.truck_photos USING btree (uploaded_at);


--
-- Name: truck_photos_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX truck_photos_user_id_index ON public.truck_photos USING btree (user_id);


--
-- Name: trucks_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX trucks_business_id_index ON public.trucks USING btree (business_id);


--
-- Name: users_business_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_business_id_index ON public.users USING btree (business_id);


--
-- Name: users_company_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_company_id_index ON public.users USING btree (company_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_specialist_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_specialist_id_index ON public.users USING btree (specialist_id);


--
-- Name: workflow_assignments_assignable_type_assignable_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_assignments_assignable_type_assignable_id_index ON public.workflow_assignments USING btree (assignable_type, assignable_id);


--
-- Name: workflow_assignments_workflow_id_current_state_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_assignments_workflow_id_current_state_id_index ON public.workflow_assignments USING btree (workflow_id, current_state_id);


--
-- Name: workflow_state_changes_changed_by_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_state_changes_changed_by_id_index ON public.workflow_state_changes USING btree (changed_by_id);


--
-- Name: workflow_state_changes_workflow_assignment_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_state_changes_workflow_assignment_id_index ON public.workflow_state_changes USING btree (workflow_assignment_id);


--
-- Name: workflow_states_workflow_id_order_index_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_states_workflow_id_order_index_index ON public.workflow_states USING btree (workflow_id, order_index);


--
-- Name: workflow_transitions_workflow_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflow_transitions_workflow_id_index ON public.workflow_transitions USING btree (workflow_id);


--
-- Name: workflows_business_id_workflow_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workflows_business_id_workflow_type_index ON public.workflows USING btree (business_id, workflow_type);


--
-- Name: activities activities_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: activities activities_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: activities activities_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: activities activities_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: activities activities_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE SET NULL;


--
-- Name: activities activities_package_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_package_assignment_id_fkey FOREIGN KEY (package_assignment_id) REFERENCES public.package_assignments(id) ON DELETE RESTRICT;


--
-- Name: activities activities_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE RESTRICT;


--
-- Name: activities activities_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE RESTRICT;


--
-- Name: activities activities_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE SET NULL;


--
-- Name: activities activities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: activity_logs activity_logs_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id);


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: companies companies_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: contacts contacts_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: contacts contacts_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: contacts contacts_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: feedback_comments feedback_comments_feedback_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_comments
    ADD CONSTRAINT feedback_comments_feedback_report_id_fkey FOREIGN KEY (feedback_report_id) REFERENCES public.feedback_reports(id) ON DELETE CASCADE;


--
-- Name: leads leads_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: leads leads_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: leads leads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: maintenance_ticket_checkouts maintenance_ticket_checkouts_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_ticket_checkouts
    ADD CONSTRAINT maintenance_ticket_checkouts_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE CASCADE;


--
-- Name: maintenance_tickets maintenance_tickets_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: maintenance_tickets maintenance_tickets_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_quotation_id_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotations(id);


--
-- Name: maintenance_tickets maintenance_tickets_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: maintenance_tickets maintenance_tickets_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maintenance_tickets
    ADD CONSTRAINT maintenance_tickets_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE CASCADE;


--
-- Name: material_categories material_categories_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_categories
    ADD CONSTRAINT material_categories_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: materials materials_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: materials materials_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.material_categories(id) ON DELETE CASCADE;


--
-- Name: package_assignments package_assignments_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: package_assignments package_assignments_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE RESTRICT;


--
-- Name: package_assignments package_assignments_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: package_assignments package_assignments_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_assignments
    ADD CONSTRAINT package_assignments_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id) ON DELETE RESTRICT;


--
-- Name: package_services package_services_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id) ON DELETE CASCADE;


--
-- Name: package_services package_services_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_services
    ADD CONSTRAINT package_services_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: packages packages_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: production_orders production_orders_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: production_orders production_orders_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: production_orders production_orders_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: production_orders production_orders_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE SET NULL;


--
-- Name: production_orders production_orders_workflow_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production_orders
    ADD CONSTRAINT production_orders_workflow_state_id_fkey FOREIGN KEY (workflow_state_id) REFERENCES public.workflow_states(id) ON DELETE SET NULL;


--
-- Name: quotation_options quotation_options_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quotation_options
    ADD CONSTRAINT quotation_options_quotation_id_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotations(id) ON DELETE CASCADE;


--
-- Name: quotations quotations_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: quotations quotations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: services services_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: specialists specialists_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: symasoft_imports symasoft_imports_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symasoft_imports
    ADD CONSTRAINT symasoft_imports_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: symasoft_imports symasoft_imports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symasoft_imports
    ADD CONSTRAINT symasoft_imports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: truck_models truck_models_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_models
    ADD CONSTRAINT truck_models_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: truck_notes truck_notes_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: truck_notes truck_notes_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE SET NULL;


--
-- Name: truck_notes truck_notes_production_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_production_order_id_fkey FOREIGN KEY (production_order_id) REFERENCES public.production_orders(id) ON DELETE SET NULL;


--
-- Name: truck_notes truck_notes_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE CASCADE;


--
-- Name: truck_notes truck_notes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_notes
    ADD CONSTRAINT truck_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: truck_photos truck_photos_maintenance_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_maintenance_ticket_id_fkey FOREIGN KEY (maintenance_ticket_id) REFERENCES public.maintenance_tickets(id) ON DELETE SET NULL;


--
-- Name: truck_photos truck_photos_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.trucks(id) ON DELETE CASCADE;


--
-- Name: truck_photos truck_photos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.truck_photos
    ADD CONSTRAINT truck_photos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: trucks trucks_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trucks
    ADD CONSTRAINT trucks_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: users users_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: users users_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: users users_specialist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES public.specialists(id) ON DELETE SET NULL;


--
-- Name: workflow_assignments workflow_assignments_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- Name: workflow_assignments workflow_assignments_current_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_current_state_id_fkey FOREIGN KEY (current_state_id) REFERENCES public.workflow_states(id) ON DELETE RESTRICT;


--
-- Name: workflow_assignments workflow_assignments_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE CASCADE;


--
-- Name: workflow_state_changes workflow_state_changes_changed_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_changed_by_id_fkey FOREIGN KEY (changed_by_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: workflow_state_changes workflow_state_changes_from_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_from_state_id_fkey FOREIGN KEY (from_state_id) REFERENCES public.workflow_states(id) ON DELETE RESTRICT;


--
-- Name: workflow_state_changes workflow_state_changes_to_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_to_state_id_fkey FOREIGN KEY (to_state_id) REFERENCES public.workflow_states(id) ON DELETE RESTRICT;


--
-- Name: workflow_state_changes workflow_state_changes_workflow_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state_changes
    ADD CONSTRAINT workflow_state_changes_workflow_assignment_id_fkey FOREIGN KEY (workflow_assignment_id) REFERENCES public.workflow_assignments(id) ON DELETE CASCADE;


--
-- Name: workflow_states workflow_states_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_states
    ADD CONSTRAINT workflow_states_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE CASCADE;


--
-- Name: workflow_transitions workflow_transitions_from_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_from_state_id_fkey FOREIGN KEY (from_state_id) REFERENCES public.workflow_states(id) ON DELETE CASCADE;


--
-- Name: workflow_transitions workflow_transitions_to_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_to_state_id_fkey FOREIGN KEY (to_state_id) REFERENCES public.workflow_states(id) ON DELETE CASCADE;


--
-- Name: workflow_transitions workflow_transitions_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES public.workflows(id) ON DELETE CASCADE;


--
-- Name: workflows workflows_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows
    ADD CONSTRAINT workflows_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

