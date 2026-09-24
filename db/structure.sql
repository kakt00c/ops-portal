SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: f_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
        SELECT public.unaccent('public.unaccent', $1);
      $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    "position" integer
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL,
    rotation integer DEFAULT 0
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id bigint NOT NULL,
    name character varying,
    url character varying,
    api_token_public_key character varying,
    webhook_private_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    responsible_subject_id bigint
);


--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: cms_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cms_categories (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    parent_category_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cms_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cms_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cms_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cms_categories_id_seq OWNED BY public.cms_categories.id;


--
-- Name: cms_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cms_pages (
    id bigint NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    text text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tags character varying[] DEFAULT '{}'::character varying[],
    category_id bigint NOT NULL,
    raw text NOT NULL,
    thumbnail_url character varying
);


--
-- Name: cms_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cms_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cms_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cms_pages_id_seq OWNED BY public.cms_pages.id;


--
-- Name: connector_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connector_activities (
    id bigint NOT NULL,
    triage_external_id integer,
    backoffice_external_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    connector_tenant_id bigint NOT NULL,
    legacy_id integer
);


--
-- Name: connector_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connector_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connector_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connector_activities_id_seq OWNED BY public.connector_activities.id;


--
-- Name: connector_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connector_issues (
    id bigint NOT NULL,
    triage_external_id integer,
    backoffice_external_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    connector_tenant_id bigint NOT NULL,
    legacy_id integer
);


--
-- Name: connector_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connector_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connector_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connector_issues_id_seq OWNED BY public.connector_issues.id;


--
-- Name: connector_tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connector_tenants (
    id bigint NOT NULL,
    name character varying,
    ops_api_token_private_key character varying,
    ops_api_subject_identifier integer,
    ops_webhook_public_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    backoffice_url character varying,
    backoffice_api_token character varying,
    backoffice_webhook_secret character varying,
    receive_customer_activities boolean DEFAULT false NOT NULL,
    migrate_legacy_labels boolean DEFAULT true,
    status integer DEFAULT 0 NOT NULL
);


--
-- Name: connector_tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connector_tenants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connector_tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connector_tenants_id_seq OWNED BY public.connector_tenants.id;


--
-- Name: connector_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connector_users (
    id bigint NOT NULL,
    external_id integer,
    uuid uuid,
    firstname character varying,
    lastname character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    connector_tenant_id bigint NOT NULL,
    email character varying
);


--
-- Name: connector_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connector_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connector_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connector_users_id_seq OWNED BY public.connector_users.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.districts (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer
);


--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: good_job_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description text,
    serialized_properties jsonb,
    on_finish text,
    on_success text,
    on_discard text,
    callback_queue_name text,
    callback_priority integer,
    enqueued_at timestamp(6) without time zone,
    discarded_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    jobs_finished_at timestamp(6) without time zone
);


--
-- Name: good_job_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_executions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    active_job_id uuid NOT NULL,
    job_class text,
    queue_name text,
    serialized_params jsonb,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    error text,
    error_event smallint,
    error_backtrace text[],
    process_id uuid,
    duration interval
);


--
-- Name: good_job_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_processes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    state jsonb,
    lock_type smallint
);


--
-- Name: good_job_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    key text,
    value jsonb
);


--
-- Name: good_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    queue_name text,
    priority integer,
    serialized_params jsonb,
    scheduled_at timestamp(6) without time zone,
    performed_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    error text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    active_job_id uuid,
    concurrency_key text,
    cron_key text,
    retried_good_job_id uuid,
    cron_at timestamp(6) without time zone,
    batch_id uuid,
    batch_callback_id uuid,
    is_discrete boolean,
    executions_count integer,
    job_class text,
    error_event smallint,
    labels text[],
    locked_by_id uuid,
    locked_at timestamp(6) without time zone
);


--
-- Name: issue_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issue_likes (
    id bigint NOT NULL,
    issue_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: issue_likes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issue_likes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issue_likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issue_likes_id_seq OWNED BY public.issue_likes.id;


--
-- Name: issue_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issue_subscriptions (
    id bigint NOT NULL,
    issue_id bigint NOT NULL,
    subscriber_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    email_unsubscribe_token character varying NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: issue_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issue_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issue_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issue_subscriptions_id_seq OWNED BY public.issue_subscriptions.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues (
    id bigint NOT NULL,
    title character varying NOT NULL,
    description character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_synced_at timestamp(6) without time zone,
    triage_external_id integer,
    legacy_data jsonb,
    anonymous boolean,
    latitude double precision,
    longitude double precision,
    author_id bigint,
    category_id bigint,
    state_id bigint,
    municipality_id bigint NOT NULL,
    legacy_id integer,
    municipality_district_id bigint,
    responsible_subject_id bigint,
    owner_id bigint,
    subcategory_id bigint,
    subtype_id bigint,
    address_region character varying,
    address_city character varying,
    address_municipality character varying,
    address_street character varying,
    address_house_number character varying,
    address_postcode character varying,
    issue_type integer DEFAULT 1,
    resolution_external_id integer,
    address_country character varying,
    address_country_code character varying,
    address_district character varying,
    imported_at timestamp(6) without time zone,
    likes_count integer DEFAULT 0 NOT NULL,
    public boolean DEFAULT false NOT NULL,
    responsible_subject_last_contact_at timestamp(6) without time zone,
    address_suburb character varying,
    comments_count integer DEFAULT 0 NOT NULL,
    fulltext_extra character varying,
    discussion_closed boolean DEFAULT false,
    archived_state_id bigint,
    last_activity_at timestamp(6) without time zone,
    resolution_started_at timestamp(6) without time zone,
    effective_at timestamp(6) without time zone GENERATED ALWAYS AS (COALESCE(resolution_started_at, created_at)) STORED
);


--
-- Name: issues_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_activities (
    id bigint NOT NULL,
    issue_id bigint NOT NULL,
    type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    likes_count integer DEFAULT 0 NOT NULL,
    dislikes_count integer DEFAULT 0 NOT NULL
);


--
-- Name: issues_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_activities_id_seq OWNED BY public.issues_activities.id;


--
-- Name: issues_activity_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_activity_votes (
    id bigint NOT NULL,
    activity_id bigint NOT NULL,
    voter_id bigint NOT NULL,
    vote smallint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: issues_activity_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_activity_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_activity_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_activity_votes_id_seq OWNED BY public.issues_activity_votes.id;


--
-- Name: issues_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_categories (
    id bigint NOT NULL,
    name character varying,
    name_hu character varying,
    alias character varying,
    description character varying,
    description_hu character varying,
    catch_all boolean DEFAULT false,
    weight integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    triage_external_id integer
);


--
-- Name: issues_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_categories_id_seq OWNED BY public.issues_categories.id;


--
-- Name: issues_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_comments (
    id bigint NOT NULL,
    activity_id bigint NOT NULL,
    author_name character varying,
    author_email character varying,
    text character varying,
    ip inet,
    verification integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    triage_external_id integer,
    user_author_id bigint,
    agent_author_id bigint,
    responsible_subject_author_id bigint,
    hidden boolean DEFAULT false,
    legacy_data jsonb,
    type character varying,
    imported_at timestamp(6) without time zone,
    legacy_comment_id integer,
    legacy_communication_id integer,
    uuid uuid,
    last_edited_at timestamp(6) without time zone
);


--
-- Name: issues_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_comments_id_seq OWNED BY public.issues_comments.id;


--
-- Name: issues_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_drafts (
    id bigint NOT NULL,
    title character varying,
    description character varying,
    anonymous boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    latitude double precision,
    longitude double precision,
    suggestions jsonb,
    picked_suggestion_index integer,
    checks jsonb,
    address_house_number character varying,
    address_street character varying,
    address_municipality character varying,
    address_city character varying,
    address_postcode character varying,
    address_country character varying,
    address_country_code character varying,
    category_id bigint,
    subcategory_id bigint,
    subtype_id bigint,
    author_id bigint NOT NULL,
    address_region character varying,
    latlon_from_exif boolean DEFAULT false,
    address_data jsonb,
    address_district character varying,
    submitted boolean DEFAULT false NOT NULL,
    address_suburb character varying,
    zoom integer,
    issue_type character varying DEFAULT 'issue'::character varying NOT NULL,
    duplicates_shown boolean DEFAULT false NOT NULL,
    issue_id bigint
);


--
-- Name: issues_drafts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_drafts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_drafts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_drafts_id_seq OWNED BY public.issues_drafts.id;


--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;


--
-- Name: issues_responsible_subject_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_responsible_subject_changes (
    id bigint NOT NULL,
    activity_id bigint NOT NULL,
    user_author_id bigint,
    responsible_subject_author_id bigint,
    responsible_subject_id bigint,
    text character varying,
    hidden boolean DEFAULT false NOT NULL,
    change_type integer NOT NULL,
    uuid uuid NOT NULL,
    triage_external_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: issues_responsible_subject_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_responsible_subject_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_responsible_subject_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_responsible_subject_changes_id_seq OWNED BY public.issues_responsible_subject_changes.id;


--
-- Name: issues_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_states (
    id bigint NOT NULL,
    name character varying,
    color character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    key character varying
);


--
-- Name: issues_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_states_id_seq OWNED BY public.issues_states.id;


--
-- Name: issues_subcategories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_subcategories (
    id bigint NOT NULL,
    name character varying,
    name_hu character varying,
    alias character varying,
    description character varying,
    description_hu character varying,
    catch_all boolean DEFAULT false,
    weight integer,
    category_id bigint NOT NULL,
    legacy_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: issues_subcategories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_subcategories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_subcategories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_subcategories_id_seq OWNED BY public.issues_subcategories.id;


--
-- Name: issues_subtypes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_subtypes (
    id bigint NOT NULL,
    name character varying,
    name_hu character varying,
    alias character varying,
    description character varying,
    description_hu character varying,
    catch_all boolean DEFAULT false,
    weight integer,
    subcategory_id bigint NOT NULL,
    legacy_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: issues_subtypes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_subtypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_subtypes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_subtypes_id_seq OWNED BY public.issues_subtypes.id;


--
-- Name: issues_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues_updates (
    id bigint NOT NULL,
    activity_id bigint NOT NULL,
    author_id bigint,
    name character varying,
    email character varying,
    text character varying,
    published boolean,
    ip inet,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    triage_external_id integer,
    imported_at timestamp(6) without time zone,
    uuid uuid,
    confirmed boolean DEFAULT false,
    external_id character varying,
    hidden boolean DEFAULT false,
    resolves_issue boolean DEFAULT false NOT NULL,
    verification_status integer DEFAULT 0 NOT NULL,
    last_edited_at timestamp(6) without time zone,
    confirmed_by_id bigint
);


--
-- Name: issues_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_updates_id_seq OWNED BY public.issues_updates.id;


--
-- Name: legacy_agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_agents (
    id bigint NOT NULL,
    email character varying,
    firstname character varying,
    lastname character varying,
    legacy_id integer,
    external_id integer,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    banned boolean DEFAULT false,
    login character varying,
    rights integer,
    admin_name character varying,
    phone character varying,
    password_hash character varying,
    about character varying,
    organization boolean,
    "timestamp" timestamp(6) without time zone,
    anonymous boolean DEFAULT false,
    active boolean,
    municipality_id bigint,
    created_from_app boolean DEFAULT false,
    verification character varying,
    verified boolean DEFAULT false,
    signature character varying,
    city_id integer,
    street_id bigint,
    resident boolean,
    sex integer,
    birth date,
    fcm_token character varying,
    gdpr_accepted boolean,
    exp integer,
    email_notifiable boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    display_name character varying
);


--
-- Name: legacy_agents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_agents_id_seq OWNED BY public.legacy_agents.id;


--
-- Name: legacy_alerts_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_alerts_sources (
    id bigint NOT NULL,
    legacy_id integer,
    responsible_subject_id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: legacy_alerts_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_alerts_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_alerts_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_alerts_sources_id_seq OWNED BY public.legacy_alerts_sources.id;


--
-- Name: legacy_issues_communications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_issues_communications (
    id bigint NOT NULL,
    activity_id bigint NOT NULL,
    from_responsible_subject boolean,
    subject character varying,
    message character varying,
    admin_id integer,
    person_id integer,
    user_id integer,
    text character varying,
    solved_by character varying,
    solved_in character varying,
    solved boolean,
    solution_rejected boolean,
    email character varying,
    ip inet,
    internal boolean,
    confirmation_needed boolean,
    plain_message character varying,
    signature character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    triage_external_id integer,
    agent_author_id bigint,
    responsible_subjects_user_author_id bigint,
    type character varying,
    imported_at timestamp(6) without time zone,
    uuid uuid
);


--
-- Name: legacy_issues_communications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_issues_communications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_issues_communications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_issues_communications_id_seq OWNED BY public.legacy_issues_communications.id;


--
-- Name: legacy_labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_labels (
    id bigint NOT NULL,
    legacy_id integer,
    responsible_subject_id bigint NOT NULL,
    name character varying,
    color character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: legacy_labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_labels_id_seq OWNED BY public.legacy_labels.id;


--
-- Name: legacy_prefetched_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_prefetched_blobs (
    id bigint NOT NULL,
    url character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: legacy_prefetched_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_prefetched_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_prefetched_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_prefetched_blobs_id_seq OWNED BY public.legacy_prefetched_blobs.id;


--
-- Name: municipalities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.municipalities (
    id bigint NOT NULL,
    name character varying,
    district_id bigint,
    sub character varying,
    email character varying,
    municipality_type integer,
    has_municipality_districts boolean,
    handled_by integer,
    latitude double precision,
    longitude double precision,
    population integer,
    active boolean,
    category integer,
    languages character varying,
    logo character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    aliases character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    active_on_old_portal boolean DEFAULT false NOT NULL,
    archived boolean DEFAULT false
);


--
-- Name: municipalities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.municipalities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: municipalities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.municipalities_id_seq OWNED BY public.municipalities.id;


--
-- Name: municipality_boundaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.municipality_boundaries (
    id bigint NOT NULL,
    municipality_id bigint,
    municipality_district_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    boundary public.geometry(Geometry,4326) NOT NULL,
    boundary_kind character varying DEFAULT 'municipality'::character varying NOT NULL
);


--
-- Name: municipality_boundaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.municipality_boundaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: municipality_boundaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.municipality_boundaries_id_seq OWNED BY public.municipality_boundaries.id;


--
-- Name: municipality_districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.municipality_districts (
    id bigint NOT NULL,
    name character varying,
    municipality_id bigint NOT NULL,
    genitiv character varying,
    lokal character varying,
    description character varying,
    logo character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    aliases character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    archived boolean DEFAULT false,
    active boolean DEFAULT false
);


--
-- Name: municipality_districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.municipality_districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: municipality_districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.municipality_districts_id_seq OWNED BY public.municipality_districts.id;


--
-- Name: responsible_subjects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responsible_subjects (
    id bigint NOT NULL,
    district_id bigint,
    municipality_id bigint,
    responsible_subjects_type_id bigint NOT NULL,
    municipality_district_id bigint,
    scope integer,
    subject_name character varying,
    email character varying,
    name character varying,
    code character varying,
    active boolean,
    pro boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    external_id character varying
);


--
-- Name: responsible_subjects_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responsible_subjects_categories (
    id bigint NOT NULL,
    responsible_subject_id bigint,
    issues_category_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    issues_subcategory_id bigint,
    issues_subtype_id bigint
);


--
-- Name: responsible_subjects_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responsible_subjects_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responsible_subjects_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responsible_subjects_categories_id_seq OWNED BY public.responsible_subjects_categories.id;


--
-- Name: responsible_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responsible_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responsible_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responsible_subjects_id_seq OWNED BY public.responsible_subjects.id;


--
-- Name: responsible_subjects_organization_units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responsible_subjects_organization_units (
    id bigint NOT NULL,
    responsible_subject_id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer
);


--
-- Name: responsible_subjects_organization_units_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responsible_subjects_organization_units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responsible_subjects_organization_units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responsible_subjects_organization_units_id_seq OWNED BY public.responsible_subjects_organization_units.id;


--
-- Name: responsible_subjects_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responsible_subjects_types (
    id bigint NOT NULL,
    name character varying,
    active boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer
);


--
-- Name: responsible_subjects_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responsible_subjects_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responsible_subjects_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responsible_subjects_types_id_seq OWNED BY public.responsible_subjects_types.id;


--
-- Name: responsible_subjects_user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responsible_subjects_user_roles (
    id bigint NOT NULL,
    slug character varying,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer
);


--
-- Name: responsible_subjects_user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responsible_subjects_user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responsible_subjects_user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responsible_subjects_user_roles_id_seq OWNED BY public.responsible_subjects_user_roles.id;


--
-- Name: responsible_subjects_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responsible_subjects_users (
    id bigint NOT NULL,
    responsible_subject_id bigint,
    role_id bigint NOT NULL,
    login character varying,
    name character varying,
    email character varying,
    token character varying,
    photo character varying,
    deleted_at timestamp(6) without time zone,
    organization_unit_id bigint,
    gdpr_accepted boolean,
    tooltips boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer
);


--
-- Name: responsible_subjects_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responsible_subjects_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responsible_subjects_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responsible_subjects_users_id_seq OWNED BY public.responsible_subjects_users.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: streets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.streets (
    id bigint NOT NULL,
    name character varying,
    municipality_id bigint NOT NULL,
    municipality_district_id bigint,
    place_identifier character varying,
    latitude double precision,
    longitude double precision,
    tested boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    legacy_id integer,
    whitelisted boolean DEFAULT false
);


--
-- Name: streets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.streets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: streets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.streets_id_seq OWNED BY public.streets.id;


--
-- Name: user_email_auth_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_email_auth_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    deadline timestamp(6) without time zone NOT NULL,
    email_last_sent timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_email_auth_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_email_auth_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_email_auth_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_email_auth_keys_id_seq OWNED BY public.user_email_auth_keys.id;


--
-- Name: user_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_identities (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    provider character varying NOT NULL,
    uid character varying NOT NULL
);


--
-- Name: user_identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_identities_id_seq OWNED BY public.user_identities.id;


--
-- Name: user_login_change_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_login_change_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    login character varying NOT NULL,
    deadline timestamp(6) without time zone NOT NULL
);


--
-- Name: user_login_change_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_login_change_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_login_change_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_login_change_keys_id_seq OWNED BY public.user_login_change_keys.id;


--
-- Name: user_password_reset_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_password_reset_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    deadline timestamp(6) without time zone NOT NULL,
    email_last_sent timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_password_reset_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_password_reset_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_password_reset_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_password_reset_keys_id_seq OWNED BY public.user_password_reset_keys.id;


--
-- Name: user_remember_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_remember_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    deadline timestamp(6) without time zone NOT NULL
);


--
-- Name: user_remember_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_remember_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_remember_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_remember_keys_id_seq OWNED BY public.user_remember_keys.id;


--
-- Name: user_verification_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_verification_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    requested_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    email_last_sent timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_verification_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_verification_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_verification_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_verification_keys_id_seq OWNED BY public.user_verification_keys.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    firstname character varying,
    lastname character varying,
    external_id integer,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    banned boolean DEFAULT false,
    login character varying,
    admin_name character varying,
    phone character varying,
    password_hash character varying,
    about character varying,
    organization boolean,
    "timestamp" timestamp(6) without time zone,
    anonymous boolean DEFAULT false,
    active boolean,
    municipality_id bigint,
    created_from_app boolean DEFAULT false,
    verification character varying,
    verified boolean DEFAULT false,
    signature character varying,
    city_id integer,
    street_id bigint,
    resident boolean,
    sex integer,
    birth date,
    fcm_token character varying,
    gdpr_accepted boolean,
    exp integer,
    email_notifiable boolean DEFAULT true,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    legacy_id integer,
    status integer DEFAULT 1 NOT NULL,
    display_name character varying,
    gdpr_stats_accepted boolean DEFAULT false,
    onboarded boolean DEFAULT false,
    newsletter_accepted boolean DEFAULT false NOT NULL,
    phone_verified boolean DEFAULT false NOT NULL,
    phone_verification_attempts integer DEFAULT 0 NOT NULL,
    phone_verification_code character varying,
    phone_verification_code_attempts integer DEFAULT 0 NOT NULL,
    phone_verification_attempted_at timestamp(6) without time zone,
    email_global_unsubscribe_token character varying NOT NULL,
    stats_issues_count integer DEFAULT 0,
    stats_comments_count integer DEFAULT 0,
    stats_verified_issues_count integer DEFAULT 0,
    stats_issues_percentile numeric(5,4) DEFAULT 0.0,
    stats_comments_percentile numeric(5,4) DEFAULT 0.0,
    stats_verified_issues_percentile numeric(5,4) DEFAULT 0.0,
    imported_at timestamp(6) without time zone,
    responsible_subject_id bigint,
    type character varying,
    CONSTRAINT valid_email CHECK ((email OPERATOR(public.~) '^[^,;@ 
]+@[^,@; 
]+\.[^,@; 
]+$'::public.citext))
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
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: cms_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cms_categories ALTER COLUMN id SET DEFAULT nextval('public.cms_categories_id_seq'::regclass);


--
-- Name: cms_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cms_pages ALTER COLUMN id SET DEFAULT nextval('public.cms_pages_id_seq'::regclass);


--
-- Name: connector_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_activities ALTER COLUMN id SET DEFAULT nextval('public.connector_activities_id_seq'::regclass);


--
-- Name: connector_issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_issues ALTER COLUMN id SET DEFAULT nextval('public.connector_issues_id_seq'::regclass);


--
-- Name: connector_tenants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_tenants ALTER COLUMN id SET DEFAULT nextval('public.connector_tenants_id_seq'::regclass);


--
-- Name: connector_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_users ALTER COLUMN id SET DEFAULT nextval('public.connector_users_id_seq'::regclass);


--
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: issue_likes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_likes ALTER COLUMN id SET DEFAULT nextval('public.issue_likes_id_seq'::regclass);


--
-- Name: issue_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.issue_subscriptions_id_seq'::regclass);


--
-- Name: issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);


--
-- Name: issues_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_activities ALTER COLUMN id SET DEFAULT nextval('public.issues_activities_id_seq'::regclass);


--
-- Name: issues_activity_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_activity_votes ALTER COLUMN id SET DEFAULT nextval('public.issues_activity_votes_id_seq'::regclass);


--
-- Name: issues_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_categories ALTER COLUMN id SET DEFAULT nextval('public.issues_categories_id_seq'::regclass);


--
-- Name: issues_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_comments ALTER COLUMN id SET DEFAULT nextval('public.issues_comments_id_seq'::regclass);


--
-- Name: issues_drafts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_drafts ALTER COLUMN id SET DEFAULT nextval('public.issues_drafts_id_seq'::regclass);


--
-- Name: issues_responsible_subject_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_responsible_subject_changes ALTER COLUMN id SET DEFAULT nextval('public.issues_responsible_subject_changes_id_seq'::regclass);


--
-- Name: issues_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_states ALTER COLUMN id SET DEFAULT nextval('public.issues_states_id_seq'::regclass);


--
-- Name: issues_subcategories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_subcategories ALTER COLUMN id SET DEFAULT nextval('public.issues_subcategories_id_seq'::regclass);


--
-- Name: issues_subtypes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_subtypes ALTER COLUMN id SET DEFAULT nextval('public.issues_subtypes_id_seq'::regclass);


--
-- Name: issues_updates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_updates ALTER COLUMN id SET DEFAULT nextval('public.issues_updates_id_seq'::regclass);


--
-- Name: legacy_agents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_agents ALTER COLUMN id SET DEFAULT nextval('public.legacy_agents_id_seq'::regclass);


--
-- Name: legacy_alerts_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_alerts_sources ALTER COLUMN id SET DEFAULT nextval('public.legacy_alerts_sources_id_seq'::regclass);


--
-- Name: legacy_issues_communications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_issues_communications ALTER COLUMN id SET DEFAULT nextval('public.legacy_issues_communications_id_seq'::regclass);


--
-- Name: legacy_labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_labels ALTER COLUMN id SET DEFAULT nextval('public.legacy_labels_id_seq'::regclass);


--
-- Name: legacy_prefetched_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_prefetched_blobs ALTER COLUMN id SET DEFAULT nextval('public.legacy_prefetched_blobs_id_seq'::regclass);


--
-- Name: municipalities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipalities ALTER COLUMN id SET DEFAULT nextval('public.municipalities_id_seq'::regclass);


--
-- Name: municipality_boundaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipality_boundaries ALTER COLUMN id SET DEFAULT nextval('public.municipality_boundaries_id_seq'::regclass);


--
-- Name: municipality_districts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipality_districts ALTER COLUMN id SET DEFAULT nextval('public.municipality_districts_id_seq'::regclass);


--
-- Name: responsible_subjects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects ALTER COLUMN id SET DEFAULT nextval('public.responsible_subjects_id_seq'::regclass);


--
-- Name: responsible_subjects_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_categories ALTER COLUMN id SET DEFAULT nextval('public.responsible_subjects_categories_id_seq'::regclass);


--
-- Name: responsible_subjects_organization_units id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_organization_units ALTER COLUMN id SET DEFAULT nextval('public.responsible_subjects_organization_units_id_seq'::regclass);


--
-- Name: responsible_subjects_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_types ALTER COLUMN id SET DEFAULT nextval('public.responsible_subjects_types_id_seq'::regclass);


--
-- Name: responsible_subjects_user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_user_roles ALTER COLUMN id SET DEFAULT nextval('public.responsible_subjects_user_roles_id_seq'::regclass);


--
-- Name: responsible_subjects_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_users ALTER COLUMN id SET DEFAULT nextval('public.responsible_subjects_users_id_seq'::regclass);


--
-- Name: streets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.streets ALTER COLUMN id SET DEFAULT nextval('public.streets_id_seq'::regclass);


--
-- Name: user_email_auth_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_email_auth_keys ALTER COLUMN id SET DEFAULT nextval('public.user_email_auth_keys_id_seq'::regclass);


--
-- Name: user_identities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities ALTER COLUMN id SET DEFAULT nextval('public.user_identities_id_seq'::regclass);


--
-- Name: user_login_change_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_login_change_keys ALTER COLUMN id SET DEFAULT nextval('public.user_login_change_keys_id_seq'::regclass);


--
-- Name: user_password_reset_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_password_reset_keys ALTER COLUMN id SET DEFAULT nextval('public.user_password_reset_keys_id_seq'::regclass);


--
-- Name: user_remember_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_remember_keys ALTER COLUMN id SET DEFAULT nextval('public.user_remember_keys_id_seq'::regclass);


--
-- Name: user_verification_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification_keys ALTER COLUMN id SET DEFAULT nextval('public.user_verification_keys_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: cms_categories cms_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cms_categories
    ADD CONSTRAINT cms_categories_pkey PRIMARY KEY (id);


--
-- Name: cms_pages cms_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cms_pages
    ADD CONSTRAINT cms_pages_pkey PRIMARY KEY (id);


--
-- Name: connector_activities connector_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_activities
    ADD CONSTRAINT connector_activities_pkey PRIMARY KEY (id);


--
-- Name: connector_issues connector_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_issues
    ADD CONSTRAINT connector_issues_pkey PRIMARY KEY (id);


--
-- Name: connector_tenants connector_tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_tenants
    ADD CONSTRAINT connector_tenants_pkey PRIMARY KEY (id);


--
-- Name: connector_users connector_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_users
    ADD CONSTRAINT connector_users_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: good_job_batches good_job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_batches
    ADD CONSTRAINT good_job_batches_pkey PRIMARY KEY (id);


--
-- Name: good_job_executions good_job_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_executions
    ADD CONSTRAINT good_job_executions_pkey PRIMARY KEY (id);


--
-- Name: good_job_processes good_job_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_processes
    ADD CONSTRAINT good_job_processes_pkey PRIMARY KEY (id);


--
-- Name: good_job_settings good_job_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_settings
    ADD CONSTRAINT good_job_settings_pkey PRIMARY KEY (id);


--
-- Name: good_jobs good_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_jobs
    ADD CONSTRAINT good_jobs_pkey PRIMARY KEY (id);


--
-- Name: issue_likes issue_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_likes
    ADD CONSTRAINT issue_likes_pkey PRIMARY KEY (id);


--
-- Name: issue_subscriptions issue_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_subscriptions
    ADD CONSTRAINT issue_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: issues_activities issues_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_activities
    ADD CONSTRAINT issues_activities_pkey PRIMARY KEY (id);


--
-- Name: issues_activity_votes issues_activity_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_activity_votes
    ADD CONSTRAINT issues_activity_votes_pkey PRIMARY KEY (id);


--
-- Name: issues_categories issues_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_categories
    ADD CONSTRAINT issues_categories_pkey PRIMARY KEY (id);


--
-- Name: issues_comments issues_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_comments
    ADD CONSTRAINT issues_comments_pkey PRIMARY KEY (id);


--
-- Name: issues_drafts issues_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_drafts
    ADD CONSTRAINT issues_drafts_pkey PRIMARY KEY (id);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: issues_responsible_subject_changes issues_responsible_subject_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_responsible_subject_changes
    ADD CONSTRAINT issues_responsible_subject_changes_pkey PRIMARY KEY (id);


--
-- Name: issues_states issues_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_states
    ADD CONSTRAINT issues_states_pkey PRIMARY KEY (id);


--
-- Name: issues_subcategories issues_subcategories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_subcategories
    ADD CONSTRAINT issues_subcategories_pkey PRIMARY KEY (id);


--
-- Name: issues_subtypes issues_subtypes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_subtypes
    ADD CONSTRAINT issues_subtypes_pkey PRIMARY KEY (id);


--
-- Name: issues_updates issues_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_updates
    ADD CONSTRAINT issues_updates_pkey PRIMARY KEY (id);


--
-- Name: legacy_agents legacy_agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_agents
    ADD CONSTRAINT legacy_agents_pkey PRIMARY KEY (id);


--
-- Name: legacy_alerts_sources legacy_alerts_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_alerts_sources
    ADD CONSTRAINT legacy_alerts_sources_pkey PRIMARY KEY (id);


--
-- Name: legacy_issues_communications legacy_issues_communications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_issues_communications
    ADD CONSTRAINT legacy_issues_communications_pkey PRIMARY KEY (id);


--
-- Name: legacy_labels legacy_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_labels
    ADD CONSTRAINT legacy_labels_pkey PRIMARY KEY (id);


--
-- Name: legacy_prefetched_blobs legacy_prefetched_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_prefetched_blobs
    ADD CONSTRAINT legacy_prefetched_blobs_pkey PRIMARY KEY (id);


--
-- Name: municipalities municipalities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipalities
    ADD CONSTRAINT municipalities_pkey PRIMARY KEY (id);


--
-- Name: municipality_boundaries municipality_boundaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipality_boundaries
    ADD CONSTRAINT municipality_boundaries_pkey PRIMARY KEY (id);


--
-- Name: municipality_districts municipality_districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipality_districts
    ADD CONSTRAINT municipality_districts_pkey PRIMARY KEY (id);


--
-- Name: responsible_subjects_categories responsible_subjects_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_categories
    ADD CONSTRAINT responsible_subjects_categories_pkey PRIMARY KEY (id);


--
-- Name: responsible_subjects_organization_units responsible_subjects_organization_units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_organization_units
    ADD CONSTRAINT responsible_subjects_organization_units_pkey PRIMARY KEY (id);


--
-- Name: responsible_subjects responsible_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects
    ADD CONSTRAINT responsible_subjects_pkey PRIMARY KEY (id);


--
-- Name: responsible_subjects_types responsible_subjects_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_types
    ADD CONSTRAINT responsible_subjects_types_pkey PRIMARY KEY (id);


--
-- Name: responsible_subjects_user_roles responsible_subjects_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_user_roles
    ADD CONSTRAINT responsible_subjects_user_roles_pkey PRIMARY KEY (id);


--
-- Name: responsible_subjects_users responsible_subjects_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_users
    ADD CONSTRAINT responsible_subjects_users_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: streets streets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.streets
    ADD CONSTRAINT streets_pkey PRIMARY KEY (id);


--
-- Name: user_email_auth_keys user_email_auth_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_email_auth_keys
    ADD CONSTRAINT user_email_auth_keys_pkey PRIMARY KEY (id);


--
-- Name: user_identities user_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT user_identities_pkey PRIMARY KEY (id);


--
-- Name: user_login_change_keys user_login_change_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_login_change_keys
    ADD CONSTRAINT user_login_change_keys_pkey PRIMARY KEY (id);


--
-- Name: user_password_reset_keys user_password_reset_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_password_reset_keys
    ADD CONSTRAINT user_password_reset_keys_pkey PRIMARY KEY (id);


--
-- Name: user_remember_keys user_remember_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_remember_keys
    ADD CONSTRAINT user_remember_keys_pkey PRIMARY KEY (id);


--
-- Name: user_verification_keys user_verification_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification_keys
    ADD CONSTRAINT user_verification_keys_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_on_responsible_subject_author_id_fe1507ef42; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_responsible_subject_author_id_fe1507ef42 ON public.issues_responsible_subject_changes USING btree (responsible_subject_author_id);


--
-- Name: idx_on_responsible_subject_id_7ec5499a35; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_responsible_subject_id_7ec5499a35 ON public.responsible_subjects_categories USING btree (responsible_subject_id);


--
-- Name: idx_on_responsible_subject_id_eb9255125f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_responsible_subject_id_eb9255125f ON public.issues_responsible_subject_changes USING btree (responsible_subject_id);


--
-- Name: idx_on_responsible_subject_id_f2ce80d659; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_responsible_subject_id_f2ce80d659 ON public.responsible_subjects_organization_units USING btree (responsible_subject_id);


--
-- Name: idx_on_responsible_subjects_user_author_id_dc50bfe063; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_responsible_subjects_user_author_id_dc50bfe063 ON public.legacy_issues_communications USING btree (responsible_subjects_user_author_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_clients_on_responsible_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clients_on_responsible_subject_id ON public.clients USING btree (responsible_subject_id);


--
-- Name: index_cms_categories_on_parent_category_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cms_categories_on_parent_category_id_and_slug ON public.cms_categories USING btree (parent_category_id, slug);


--
-- Name: index_cms_pages_on_category_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cms_pages_on_category_id_and_slug ON public.cms_pages USING btree (category_id, slug);


--
-- Name: index_connector_activities_on_backoffice_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_activities_on_backoffice_external_id ON public.connector_activities USING btree (backoffice_external_id);


--
-- Name: index_connector_activities_on_connector_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_activities_on_connector_tenant_id ON public.connector_activities USING btree (connector_tenant_id);


--
-- Name: index_connector_activities_on_triage_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_activities_on_triage_external_id ON public.connector_activities USING btree (triage_external_id);


--
-- Name: index_connector_issues_on_backoffice_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_issues_on_backoffice_external_id ON public.connector_issues USING btree (backoffice_external_id);


--
-- Name: index_connector_issues_on_connector_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_issues_on_connector_tenant_id ON public.connector_issues USING btree (connector_tenant_id);


--
-- Name: index_connector_issues_on_triage_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_issues_on_triage_external_id ON public.connector_issues USING btree (triage_external_id);


--
-- Name: index_connector_users_on_connector_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_users_on_connector_tenant_id ON public.connector_users USING btree (connector_tenant_id);


--
-- Name: index_connector_users_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_connector_users_on_external_id ON public.connector_users USING btree (external_id);


--
-- Name: index_districts_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_districts_on_legacy_id ON public.districts USING btree (legacy_id);


--
-- Name: index_good_job_executions_on_active_job_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_job_executions_on_active_job_id_and_created_at ON public.good_job_executions USING btree (active_job_id, created_at);


--
-- Name: index_good_job_executions_on_process_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_job_executions_on_process_id_and_created_at ON public.good_job_executions USING btree (process_id, created_at);


--
-- Name: index_good_job_jobs_for_candidate_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_job_jobs_for_candidate_lookup ON public.good_jobs USING btree (priority, created_at) WHERE (finished_at IS NULL);


--
-- Name: index_good_job_settings_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_good_job_settings_on_key ON public.good_job_settings USING btree (key);


--
-- Name: index_good_jobs_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_jobs_on_finished_at ON public.good_jobs USING btree (finished_at) WHERE ((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL));


--
-- Name: index_good_jobs_jobs_on_priority_created_at_when_unfinished; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_jobs_on_priority_created_at_when_unfinished ON public.good_jobs USING btree (priority DESC NULLS LAST, created_at) WHERE (finished_at IS NULL);


--
-- Name: index_good_jobs_on_active_job_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_active_job_id_and_created_at ON public.good_jobs USING btree (active_job_id, created_at);


--
-- Name: index_good_jobs_on_batch_callback_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_batch_callback_id ON public.good_jobs USING btree (batch_callback_id) WHERE (batch_callback_id IS NOT NULL);


--
-- Name: index_good_jobs_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_batch_id ON public.good_jobs USING btree (batch_id) WHERE (batch_id IS NOT NULL);


--
-- Name: index_good_jobs_on_concurrency_key_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_concurrency_key_and_created_at ON public.good_jobs USING btree (concurrency_key, created_at);


--
-- Name: index_good_jobs_on_concurrency_key_when_unfinished; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_concurrency_key_when_unfinished ON public.good_jobs USING btree (concurrency_key) WHERE (finished_at IS NULL);


--
-- Name: index_good_jobs_on_cron_key_and_created_at_cond; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_cron_key_and_created_at_cond ON public.good_jobs USING btree (cron_key, created_at) WHERE (cron_key IS NOT NULL);


--
-- Name: index_good_jobs_on_cron_key_and_cron_at_cond; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_good_jobs_on_cron_key_and_cron_at_cond ON public.good_jobs USING btree (cron_key, cron_at) WHERE (cron_key IS NOT NULL);


--
-- Name: index_good_jobs_on_job_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_job_class ON public.good_jobs USING btree (job_class);


--
-- Name: index_good_jobs_on_labels; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_labels ON public.good_jobs USING gin (labels) WHERE (labels IS NOT NULL);


--
-- Name: index_good_jobs_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_locked_by_id ON public.good_jobs USING btree (locked_by_id) WHERE (locked_by_id IS NOT NULL);


--
-- Name: index_good_jobs_on_priority_scheduled_at_unfinished_unlocked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_priority_scheduled_at_unfinished_unlocked ON public.good_jobs USING btree (priority, scheduled_at) WHERE ((finished_at IS NULL) AND (locked_by_id IS NULL));


--
-- Name: index_good_jobs_on_queue_name_and_scheduled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_queue_name_and_scheduled_at ON public.good_jobs USING btree (queue_name, scheduled_at) WHERE (finished_at IS NULL);


--
-- Name: index_good_jobs_on_scheduled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_scheduled_at ON public.good_jobs USING btree (scheduled_at) WHERE (finished_at IS NULL);


--
-- Name: index_issue_likes_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_likes_on_issue_id ON public.issue_likes USING btree (issue_id);


--
-- Name: index_issue_likes_on_issue_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issue_likes_on_issue_id_and_user_id ON public.issue_likes USING btree (issue_id, user_id);


--
-- Name: index_issue_likes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_likes_on_user_id ON public.issue_likes USING btree (user_id);


--
-- Name: index_issue_subscriptions_on_email_unsubscribe_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issue_subscriptions_on_email_unsubscribe_token ON public.issue_subscriptions USING btree (email_unsubscribe_token);


--
-- Name: index_issue_subscriptions_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_subscriptions_on_issue_id ON public.issue_subscriptions USING btree (issue_id);


--
-- Name: index_issue_subscriptions_on_issue_id_and_subscriber_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issue_subscriptions_on_issue_id_and_subscriber_id ON public.issue_subscriptions USING btree (issue_id, subscriber_id);


--
-- Name: index_issue_subscriptions_on_subscriber_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_subscriptions_on_subscriber_id ON public.issue_subscriptions USING btree (subscriber_id);


--
-- Name: index_issues_activities_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_activities_on_issue_id ON public.issues_activities USING btree (issue_id);


--
-- Name: index_issues_activity_votes_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_activity_votes_on_activity_id ON public.issues_activity_votes USING btree (activity_id);


--
-- Name: index_issues_activity_votes_on_activity_id_and_voter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_activity_votes_on_activity_id_and_voter_id ON public.issues_activity_votes USING btree (activity_id, voter_id);


--
-- Name: index_issues_activity_votes_on_voter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_activity_votes_on_voter_id ON public.issues_activity_votes USING btree (voter_id);


--
-- Name: index_issues_categories_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_categories_on_legacy_id ON public.issues_categories USING btree (legacy_id);


--
-- Name: index_issues_comments_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_comments_on_activity_id ON public.issues_comments USING btree (activity_id);


--
-- Name: index_issues_comments_on_agent_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_comments_on_agent_author_id ON public.issues_comments USING btree (agent_author_id);


--
-- Name: index_issues_comments_on_legacy_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_comments_on_legacy_comment_id ON public.issues_comments USING btree (legacy_comment_id);


--
-- Name: index_issues_comments_on_legacy_communication_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_comments_on_legacy_communication_id ON public.issues_comments USING btree (legacy_communication_id);


--
-- Name: index_issues_comments_on_responsible_subject_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_comments_on_responsible_subject_author_id ON public.issues_comments USING btree (responsible_subject_author_id);


--
-- Name: index_issues_comments_on_user_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_comments_on_user_author_id ON public.issues_comments USING btree (user_author_id);


--
-- Name: index_issues_comments_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_comments_on_uuid ON public.issues_comments USING btree (uuid);


--
-- Name: index_issues_default_search_hot_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_default_search_hot_path ON public.issues USING btree (effective_at) WHERE (state_id <> ALL (ARRAY[(3)::bigint, (7)::bigint, (10)::bigint, (12)::bigint]));


--
-- Name: index_issues_drafts_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_drafts_on_author_id ON public.issues_drafts USING btree (author_id);


--
-- Name: index_issues_drafts_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_drafts_on_category_id ON public.issues_drafts USING btree (category_id);


--
-- Name: index_issues_drafts_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_drafts_on_issue_id ON public.issues_drafts USING btree (issue_id);


--
-- Name: index_issues_drafts_on_subcategory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_drafts_on_subcategory_id ON public.issues_drafts USING btree (subcategory_id);


--
-- Name: index_issues_drafts_on_subtype_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_drafts_on_subtype_id ON public.issues_drafts USING btree (subtype_id);


--
-- Name: index_issues_municipality_effective_at_hot_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_municipality_effective_at_hot_path ON public.issues USING btree (municipality_id, effective_at) WHERE (state_id <> ALL (ARRAY[(3)::bigint, (7)::bigint, (10)::bigint, (12)::bigint]));


--
-- Name: index_issues_municipality_resolution_started_at_hot_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_municipality_resolution_started_at_hot_path ON public.issues USING btree (municipality_id, resolution_started_at) WHERE ((state_id <> ALL (ARRAY[(3)::bigint, (7)::bigint, (10)::bigint, (12)::bigint])) AND (resolution_started_at IS NOT NULL));


--
-- Name: index_issues_municipality_search_hot_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_municipality_search_hot_path ON public.issues USING btree (municipality_id, created_at) WHERE (state_id <> ALL (ARRAY[(3)::bigint, (7)::bigint, (10)::bigint, (12)::bigint]));


--
-- Name: index_issues_on_archived_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_archived_state_id ON public.issues USING btree (archived_state_id);


--
-- Name: index_issues_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_author_id ON public.issues USING btree (author_id);


--
-- Name: index_issues_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_category_id ON public.issues USING btree (category_id);


--
-- Name: index_issues_on_effective_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_effective_at ON public.issues USING btree (effective_at);


--
-- Name: index_issues_on_effective_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_effective_date ON public.issues USING btree (COALESCE(resolution_started_at, created_at) DESC);


--
-- Name: index_issues_on_last_activity_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_last_activity_at ON public.issues USING btree (last_activity_at DESC NULLS LAST);


--
-- Name: index_issues_on_lat_lon_point; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_lat_lon_point ON public.issues USING gist (public.st_point(longitude, latitude, 4326));


--
-- Name: index_issues_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_on_legacy_id ON public.issues USING btree (legacy_id);


--
-- Name: index_issues_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_location ON public.issues USING gist (((public.st_point(longitude, latitude, 4326))::public.geography));


--
-- Name: index_issues_on_municipality_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_municipality_district_id ON public.issues USING btree (municipality_district_id);


--
-- Name: index_issues_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_municipality_id ON public.issues USING btree (municipality_id);


--
-- Name: index_issues_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_owner_id ON public.issues USING btree (owner_id);


--
-- Name: index_issues_on_resolution_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_resolution_started_at ON public.issues USING btree (resolution_started_at);


--
-- Name: index_issues_on_responsible_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_responsible_subject_id ON public.issues USING btree (responsible_subject_id);


--
-- Name: index_issues_on_responsible_subject_last_contact_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_responsible_subject_last_contact_at ON public.issues USING btree (responsible_subject_last_contact_at);


--
-- Name: index_issues_on_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_state_id ON public.issues USING btree (state_id);


--
-- Name: index_issues_on_subcategory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_subcategory_id ON public.issues USING btree (subcategory_id);


--
-- Name: index_issues_on_subtype_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_subtype_id ON public.issues USING btree (subtype_id);


--
-- Name: index_issues_resolution_started_at_hot_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_resolution_started_at_hot_path ON public.issues USING btree (resolution_started_at) WHERE ((state_id <> ALL (ARRAY[(3)::bigint, (7)::bigint, (10)::bigint, (12)::bigint])) AND (resolution_started_at IS NOT NULL));


--
-- Name: index_issues_responsible_subject_changes_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_responsible_subject_changes_on_activity_id ON public.issues_responsible_subject_changes USING btree (activity_id);


--
-- Name: index_issues_responsible_subject_changes_on_user_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_responsible_subject_changes_on_user_author_id ON public.issues_responsible_subject_changes USING btree (user_author_id);


--
-- Name: index_issues_states_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_states_on_key ON public.issues_states USING btree (key);


--
-- Name: index_issues_states_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_states_on_legacy_id ON public.issues_states USING btree (legacy_id);


--
-- Name: index_issues_subcategories_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_subcategories_on_category_id ON public.issues_subcategories USING btree (category_id);


--
-- Name: index_issues_subcategories_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_subcategories_on_legacy_id ON public.issues_subcategories USING btree (legacy_id);


--
-- Name: index_issues_subtypes_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_subtypes_on_legacy_id ON public.issues_subtypes USING btree (legacy_id);


--
-- Name: index_issues_subtypes_on_subcategory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_subtypes_on_subcategory_id ON public.issues_subtypes USING btree (subcategory_id);


--
-- Name: index_issues_updates_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_updates_on_activity_id ON public.issues_updates USING btree (activity_id);


--
-- Name: index_issues_updates_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_updates_on_author_id ON public.issues_updates USING btree (author_id);


--
-- Name: index_issues_updates_on_confirmed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_updates_on_confirmed_by_id ON public.issues_updates USING btree (confirmed_by_id);


--
-- Name: index_issues_updates_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_updates_on_external_id ON public.issues_updates USING btree (external_id);


--
-- Name: index_issues_updates_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_updates_on_legacy_id ON public.issues_updates USING btree (legacy_id);


--
-- Name: index_issues_updates_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_issues_updates_on_uuid ON public.issues_updates USING btree (uuid);


--
-- Name: index_legacy_agents_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_agents_on_external_id ON public.legacy_agents USING btree (external_id);


--
-- Name: index_legacy_agents_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_agents_on_municipality_id ON public.legacy_agents USING btree (municipality_id);


--
-- Name: index_legacy_agents_on_street_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_agents_on_street_id ON public.legacy_agents USING btree (street_id);


--
-- Name: index_legacy_alerts_sources_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_alerts_sources_on_legacy_id ON public.legacy_alerts_sources USING btree (legacy_id);


--
-- Name: index_legacy_alerts_sources_on_responsible_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_alerts_sources_on_responsible_subject_id ON public.legacy_alerts_sources USING btree (responsible_subject_id);


--
-- Name: index_legacy_issues_communications_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_issues_communications_on_activity_id ON public.legacy_issues_communications USING btree (activity_id);


--
-- Name: index_legacy_issues_communications_on_agent_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_issues_communications_on_agent_author_id ON public.legacy_issues_communications USING btree (agent_author_id);


--
-- Name: index_legacy_issues_communications_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_issues_communications_on_legacy_id ON public.legacy_issues_communications USING btree (legacy_id);


--
-- Name: index_legacy_issues_communications_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_issues_communications_on_uuid ON public.legacy_issues_communications USING btree (uuid);


--
-- Name: index_legacy_labels_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_labels_on_legacy_id ON public.legacy_labels USING btree (legacy_id);


--
-- Name: index_legacy_labels_on_responsible_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_labels_on_responsible_subject_id ON public.legacy_labels USING btree (responsible_subject_id);


--
-- Name: index_legacy_prefetched_blobs_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_prefetched_blobs_on_url ON public.legacy_prefetched_blobs USING btree (url);


--
-- Name: index_municipalities_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipalities_on_active ON public.municipalities USING btree (active);


--
-- Name: index_municipalities_on_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipalities_on_district_id ON public.municipalities USING btree (district_id);


--
-- Name: index_municipalities_on_latitude; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipalities_on_latitude ON public.municipalities USING btree (latitude);


--
-- Name: index_municipalities_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_municipalities_on_legacy_id ON public.municipalities USING btree (legacy_id);


--
-- Name: index_municipalities_on_longitude; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipalities_on_longitude ON public.municipalities USING btree (longitude);


--
-- Name: index_municipality_boundaries_on_boundary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipality_boundaries_on_boundary ON public.municipality_boundaries USING gist (boundary);


--
-- Name: index_municipality_boundaries_on_municipality_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipality_boundaries_on_municipality_district_id ON public.municipality_boundaries USING btree (municipality_district_id);


--
-- Name: index_municipality_boundaries_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipality_boundaries_on_municipality_id ON public.municipality_boundaries USING btree (municipality_id);


--
-- Name: index_municipality_districts_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_municipality_districts_on_legacy_id ON public.municipality_districts USING btree (legacy_id);


--
-- Name: index_municipality_districts_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_municipality_districts_on_municipality_id ON public.municipality_districts USING btree (municipality_id);


--
-- Name: index_responsible_subjects_categories_on_issues_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_categories_on_issues_category_id ON public.responsible_subjects_categories USING btree (issues_category_id);


--
-- Name: index_responsible_subjects_categories_on_issues_subcategory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_categories_on_issues_subcategory_id ON public.responsible_subjects_categories USING btree (issues_subcategory_id);


--
-- Name: index_responsible_subjects_categories_on_issues_subtype_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_categories_on_issues_subtype_id ON public.responsible_subjects_categories USING btree (issues_subtype_id);


--
-- Name: index_responsible_subjects_categories_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_responsible_subjects_categories_on_legacy_id ON public.responsible_subjects_categories USING btree (legacy_id);


--
-- Name: index_responsible_subjects_on_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_on_district_id ON public.responsible_subjects USING btree (district_id);


--
-- Name: index_responsible_subjects_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_responsible_subjects_on_legacy_id ON public.responsible_subjects USING btree (legacy_id);


--
-- Name: index_responsible_subjects_on_municipality_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_on_municipality_district_id ON public.responsible_subjects USING btree (municipality_district_id);


--
-- Name: index_responsible_subjects_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_on_municipality_id ON public.responsible_subjects USING btree (municipality_id);


--
-- Name: index_responsible_subjects_on_responsible_subjects_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_on_responsible_subjects_type_id ON public.responsible_subjects USING btree (responsible_subjects_type_id);


--
-- Name: index_responsible_subjects_organization_units_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_responsible_subjects_organization_units_on_legacy_id ON public.responsible_subjects_organization_units USING btree (legacy_id);


--
-- Name: index_responsible_subjects_types_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_responsible_subjects_types_on_legacy_id ON public.responsible_subjects_types USING btree (legacy_id);


--
-- Name: index_responsible_subjects_user_roles_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_responsible_subjects_user_roles_on_legacy_id ON public.responsible_subjects_user_roles USING btree (legacy_id);


--
-- Name: index_responsible_subjects_users_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_responsible_subjects_users_on_legacy_id ON public.responsible_subjects_users USING btree (legacy_id);


--
-- Name: index_responsible_subjects_users_on_organization_unit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_users_on_organization_unit_id ON public.responsible_subjects_users USING btree (organization_unit_id);


--
-- Name: index_responsible_subjects_users_on_responsible_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_users_on_responsible_subject_id ON public.responsible_subjects_users USING btree (responsible_subject_id);


--
-- Name: index_responsible_subjects_users_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_responsible_subjects_users_on_role_id ON public.responsible_subjects_users USING btree (role_id);


--
-- Name: index_streets_on_latitude; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_streets_on_latitude ON public.streets USING btree (latitude);


--
-- Name: index_streets_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_streets_on_legacy_id ON public.streets USING btree (legacy_id);


--
-- Name: index_streets_on_longitude; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_streets_on_longitude ON public.streets USING btree (longitude);


--
-- Name: index_streets_on_municipality_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_streets_on_municipality_district_id ON public.streets USING btree (municipality_district_id);


--
-- Name: index_streets_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_streets_on_municipality_id ON public.streets USING btree (municipality_id);


--
-- Name: index_user_identities_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_identities_on_provider_and_uid ON public.user_identities USING btree (provider, uid);


--
-- Name: index_user_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_identities_on_user_id ON public.user_identities USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email) WHERE (status = ANY (ARRAY[1, 2]));


--
-- Name: index_users_on_email_global_unsubscribe_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_global_unsubscribe_token ON public.users USING btree (email_global_unsubscribe_token);


--
-- Name: index_users_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_external_id ON public.users USING btree (external_id);


--
-- Name: index_users_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_legacy_id ON public.users USING btree (legacy_id);


--
-- Name: index_users_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_municipality_id ON public.users USING btree (municipality_id);


--
-- Name: index_users_on_responsible_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_responsible_subject_id ON public.users USING btree (responsible_subject_id);


--
-- Name: index_users_on_street_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_street_id ON public.users USING btree (street_id);


--
-- Name: index_users_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_type ON public.users USING btree (type);


--
-- Name: issues_fulltext_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issues_fulltext_idx ON public.issues USING gin ((((((to_tsvector('simple'::regconfig, public.f_unaccent(COALESCE((title)::text, ''::text))) || to_tsvector('simple'::regconfig, public.f_unaccent(COALESCE((description)::text, ''::text)))) || to_tsvector('simple'::regconfig, public.f_unaccent(COALESCE((legacy_id)::text, ''::text)))) || to_tsvector('simple'::regconfig, public.f_unaccent(COALESCE((id)::text, ''::text)))) || to_tsvector('simple'::regconfig, public.f_unaccent(COALESCE((fulltext_extra)::text, ''::text))))));


--
-- Name: municipalities fk_rails_03f4031592; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipalities
    ADD CONSTRAINT fk_rails_03f4031592 FOREIGN KEY (district_id) REFERENCES public.districts(id);


--
-- Name: issues fk_rails_05f1e72feb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_05f1e72feb FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: legacy_alerts_sources fk_rails_0e2f527795; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_alerts_sources
    ADD CONSTRAINT fk_rails_0e2f527795 FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: responsible_subjects_users fk_rails_1226fa901f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_users
    ADD CONSTRAINT fk_rails_1226fa901f FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: issues_subcategories fk_rails_14cee3b872; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_subcategories
    ADD CONSTRAINT fk_rails_14cee3b872 FOREIGN KEY (category_id) REFERENCES public.issues_categories(id);


--
-- Name: user_password_reset_keys fk_rails_14f8ce8b45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_password_reset_keys
    ADD CONSTRAINT fk_rails_14f8ce8b45 FOREIGN KEY (id) REFERENCES public.users(id);


--
-- Name: user_email_auth_keys fk_rails_1a2acb61d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_email_auth_keys
    ADD CONSTRAINT fk_rails_1a2acb61d1 FOREIGN KEY (id) REFERENCES public.users(id);


--
-- Name: legacy_agents fk_rails_1b2b63ec59; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_agents
    ADD CONSTRAINT fk_rails_1b2b63ec59 FOREIGN KEY (municipality_id) REFERENCES public.municipalities(id);


--
-- Name: issue_subscriptions fk_rails_270021a150; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_subscriptions
    ADD CONSTRAINT fk_rails_270021a150 FOREIGN KEY (subscriber_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: municipality_districts fk_rails_29db461c7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipality_districts
    ADD CONSTRAINT fk_rails_29db461c7e FOREIGN KEY (municipality_id) REFERENCES public.municipalities(id);


--
-- Name: responsible_subjects_categories fk_rails_2b65304603; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_categories
    ADD CONSTRAINT fk_rails_2b65304603 FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: issues_drafts fk_rails_2c992b0e3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_drafts
    ADD CONSTRAINT fk_rails_2c992b0e3d FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: legacy_issues_communications fk_rails_35b4962c3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_issues_communications
    ADD CONSTRAINT fk_rails_35b4962c3d FOREIGN KEY (responsible_subjects_user_author_id) REFERENCES public.responsible_subjects_users(id);


--
-- Name: issues_responsible_subject_changes fk_rails_3919e03351; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_responsible_subject_changes
    ADD CONSTRAINT fk_rails_3919e03351 FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: issues fk_rails_44771000d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_44771000d0 FOREIGN KEY (owner_id) REFERENCES public.legacy_agents(id);


--
-- Name: issues_drafts fk_rails_48d35cb239; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_drafts
    ADD CONSTRAINT fk_rails_48d35cb239 FOREIGN KEY (category_id) REFERENCES public.issues_categories(id);


--
-- Name: issues_updates fk_rails_493cf6c7c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_updates
    ADD CONSTRAINT fk_rails_493cf6c7c3 FOREIGN KEY (activity_id) REFERENCES public.issues_activities(id);


--
-- Name: issues_drafts fk_rails_4a07ddfeff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_drafts
    ADD CONSTRAINT fk_rails_4a07ddfeff FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- Name: issues fk_rails_4e60020611; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_4e60020611 FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: issues_subtypes fk_rails_53f9ade1c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_subtypes
    ADD CONSTRAINT fk_rails_53f9ade1c3 FOREIGN KEY (subcategory_id) REFERENCES public.issues_subcategories(id);


--
-- Name: streets fk_rails_5410bc504c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.streets
    ADD CONSTRAINT fk_rails_5410bc504c FOREIGN KEY (municipality_id) REFERENCES public.municipalities(id);


--
-- Name: issues_responsible_subject_changes fk_rails_5457923ea3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_responsible_subject_changes
    ADD CONSTRAINT fk_rails_5457923ea3 FOREIGN KEY (activity_id) REFERENCES public.issues_activities(id);


--
-- Name: responsible_subjects_categories fk_rails_5506f30cd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_categories
    ADD CONSTRAINT fk_rails_5506f30cd0 FOREIGN KEY (issues_category_id) REFERENCES public.issues_categories(id);


--
-- Name: issues_comments fk_rails_5933b4d6cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_comments
    ADD CONSTRAINT fk_rails_5933b4d6cf FOREIGN KEY (user_author_id) REFERENCES public.users(id);


--
-- Name: responsible_subjects fk_rails_5a44725c89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects
    ADD CONSTRAINT fk_rails_5a44725c89 FOREIGN KEY (responsible_subjects_type_id) REFERENCES public.responsible_subjects_types(id);


--
-- Name: issue_likes fk_rails_5cd49958f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_likes
    ADD CONSTRAINT fk_rails_5cd49958f8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: issues_comments fk_rails_5ee98eebd6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_comments
    ADD CONSTRAINT fk_rails_5ee98eebd6 FOREIGN KEY (activity_id) REFERENCES public.issues_activities(id);


--
-- Name: connector_users fk_rails_5f56c261d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_users
    ADD CONSTRAINT fk_rails_5f56c261d9 FOREIGN KEY (connector_tenant_id) REFERENCES public.connector_tenants(id);


--
-- Name: streets fk_rails_64249db34e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.streets
    ADD CONSTRAINT fk_rails_64249db34e FOREIGN KEY (municipality_district_id) REFERENCES public.municipality_districts(id);


--
-- Name: issues fk_rails_6552e9638d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_6552e9638d FOREIGN KEY (state_id) REFERENCES public.issues_states(id);


--
-- Name: issue_subscriptions fk_rails_674fc368a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_subscriptions
    ADD CONSTRAINT fk_rails_674fc368a2 FOREIGN KEY (issue_id) REFERENCES public.issues(id) ON DELETE CASCADE;


--
-- Name: user_identities fk_rails_684b0e1ce0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT fk_rails_684b0e1ce0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: municipality_boundaries fk_rails_6ac85b5672; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipality_boundaries
    ADD CONSTRAINT fk_rails_6ac85b5672 FOREIGN KEY (municipality_district_id) REFERENCES public.municipality_districts(id);


--
-- Name: issues fk_rails_6e8f6d948e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_6e8f6d948e FOREIGN KEY (archived_state_id) REFERENCES public.issues_states(id);


--
-- Name: issues_drafts fk_rails_754b96099f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_drafts
    ADD CONSTRAINT fk_rails_754b96099f FOREIGN KEY (subtype_id) REFERENCES public.issues_subtypes(id);


--
-- Name: user_login_change_keys fk_rails_75ab774cc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_login_change_keys
    ADD CONSTRAINT fk_rails_75ab774cc7 FOREIGN KEY (id) REFERENCES public.users(id);


--
-- Name: issues_responsible_subject_changes fk_rails_761d55b5c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_responsible_subject_changes
    ADD CONSTRAINT fk_rails_761d55b5c7 FOREIGN KEY (responsible_subject_author_id) REFERENCES public.responsible_subjects(id);


--
-- Name: responsible_subjects fk_rails_77e9cc3151; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects
    ADD CONSTRAINT fk_rails_77e9cc3151 FOREIGN KEY (district_id) REFERENCES public.districts(id);


--
-- Name: issues fk_rails_81af2103ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_81af2103ca FOREIGN KEY (municipality_district_id) REFERENCES public.municipality_districts(id);


--
-- Name: issues_activity_votes fk_rails_839e19d604; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_activity_votes
    ADD CONSTRAINT fk_rails_839e19d604 FOREIGN KEY (voter_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: issues fk_rails_847dcee27e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_847dcee27e FOREIGN KEY (category_id) REFERENCES public.issues_categories(id);


--
-- Name: issues_comments fk_rails_903df1a366; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_comments
    ADD CONSTRAINT fk_rails_903df1a366 FOREIGN KEY (agent_author_id) REFERENCES public.legacy_agents(id);


--
-- Name: issue_likes fk_rails_90e6ba2dd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_likes
    ADD CONSTRAINT fk_rails_90e6ba2dd2 FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- Name: legacy_labels fk_rails_91c3a6c92e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_labels
    ADD CONSTRAINT fk_rails_91c3a6c92e FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: responsible_subjects fk_rails_9b8752453c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects
    ADD CONSTRAINT fk_rails_9b8752453c FOREIGN KEY (municipality_district_id) REFERENCES public.municipality_districts(id);


--
-- Name: cms_pages fk_rails_9e7d844076; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cms_pages
    ADD CONSTRAINT fk_rails_9e7d844076 FOREIGN KEY (category_id) REFERENCES public.cms_categories(id) ON DELETE CASCADE;


--
-- Name: legacy_agents fk_rails_a641dfc204; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_agents
    ADD CONSTRAINT fk_rails_a641dfc204 FOREIGN KEY (street_id) REFERENCES public.streets(id);


--
-- Name: issues_comments fk_rails_a7c6858c40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_comments
    ADD CONSTRAINT fk_rails_a7c6858c40 FOREIGN KEY (responsible_subject_author_id) REFERENCES public.responsible_subjects(id);


--
-- Name: responsible_subjects_users fk_rails_a83f7cb173; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_users
    ADD CONSTRAINT fk_rails_a83f7cb173 FOREIGN KEY (role_id) REFERENCES public.responsible_subjects_user_roles(id);


--
-- Name: responsible_subjects_users fk_rails_a9071ab023; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_users
    ADD CONSTRAINT fk_rails_a9071ab023 FOREIGN KEY (organization_unit_id) REFERENCES public.responsible_subjects_organization_units(id);


--
-- Name: responsible_subjects_organization_units fk_rails_ac40c26458; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects_organization_units
    ADD CONSTRAINT fk_rails_ac40c26458 FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: municipality_boundaries fk_rails_ac7afc9016; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.municipality_boundaries
    ADD CONSTRAINT fk_rails_ac7afc9016 FOREIGN KEY (municipality_id) REFERENCES public.municipalities(id);


--
-- Name: users fk_rails_af51c67270; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_af51c67270 FOREIGN KEY (municipality_id) REFERENCES public.municipalities(id);


--
-- Name: responsible_subjects fk_rails_b01f09f6a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsible_subjects
    ADD CONSTRAINT fk_rails_b01f09f6a3 FOREIGN KEY (municipality_id) REFERENCES public.municipalities(id);


--
-- Name: users fk_rails_b204e00255; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_b204e00255 FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: legacy_issues_communications fk_rails_b3a0e7e7b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_issues_communications
    ADD CONSTRAINT fk_rails_b3a0e7e7b7 FOREIGN KEY (agent_author_id) REFERENCES public.legacy_agents(id);


--
-- Name: user_verification_keys fk_rails_b5d6b8f85b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification_keys
    ADD CONSTRAINT fk_rails_b5d6b8f85b FOREIGN KEY (id) REFERENCES public.users(id);


--
-- Name: issues_responsible_subject_changes fk_rails_bee7c2ed82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_responsible_subject_changes
    ADD CONSTRAINT fk_rails_bee7c2ed82 FOREIGN KEY (user_author_id) REFERENCES public.users(id);


--
-- Name: clients fk_rails_bff5d2adc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT fk_rails_bff5d2adc7 FOREIGN KEY (responsible_subject_id) REFERENCES public.responsible_subjects(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: issues fk_rails_cf9cb0dc20; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_cf9cb0dc20 FOREIGN KEY (subtype_id) REFERENCES public.issues_subtypes(id);


--
-- Name: issues_drafts fk_rails_d305b5e8e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_drafts
    ADD CONSTRAINT fk_rails_d305b5e8e3 FOREIGN KEY (subcategory_id) REFERENCES public.issues_subcategories(id);


--
-- Name: issues fk_rails_d85a605e0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_rails_d85a605e0e FOREIGN KEY (subcategory_id) REFERENCES public.issues_subcategories(id);


--
-- Name: users fk_rails_dc3d17a600; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_dc3d17a600 FOREIGN KEY (street_id) REFERENCES public.streets(id);


--
-- Name: issues_activity_votes fk_rails_dd8812846f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_activity_votes
    ADD CONSTRAINT fk_rails_dd8812846f FOREIGN KEY (activity_id) REFERENCES public.issues_activities(id) ON DELETE CASCADE;


--
-- Name: connector_activities fk_rails_e5c13ad0c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_activities
    ADD CONSTRAINT fk_rails_e5c13ad0c7 FOREIGN KEY (connector_tenant_id) REFERENCES public.connector_tenants(id);


--
-- Name: issues_updates fk_rails_e5ed276bbf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_updates
    ADD CONSTRAINT fk_rails_e5ed276bbf FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: connector_issues fk_rails_e842e27b3a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_issues
    ADD CONSTRAINT fk_rails_e842e27b3a FOREIGN KEY (connector_tenant_id) REFERENCES public.connector_tenants(id);


--
-- Name: user_remember_keys fk_rails_ee6b3c037b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_remember_keys
    ADD CONSTRAINT fk_rails_ee6b3c037b FOREIGN KEY (id) REFERENCES public.users(id);


--
-- Name: issues_activities fk_rails_ef1ada5578; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_activities
    ADD CONSTRAINT fk_rails_ef1ada5578 FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- Name: legacy_issues_communications fk_rails_f4db0cf30b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_issues_communications
    ADD CONSTRAINT fk_rails_f4db0cf30b FOREIGN KEY (activity_id) REFERENCES public.issues_activities(id);


--
-- Name: issues_updates fk_rails_f6e3cb8d90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues_updates
    ADD CONSTRAINT fk_rails_f6e3cb8d90 FOREIGN KEY (confirmed_by_id) REFERENCES public.legacy_agents(id);


--
-- Name: cms_categories fk_rails_f8cce9e30c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cms_categories
    ADD CONSTRAINT fk_rails_f8cce9e30c FOREIGN KEY (parent_category_id) REFERENCES public.cms_categories(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260705131733'),
('20260524143000'),
('20260524134500'),
('20260524113000'),
('20260522170432'),
('20260522000002'),
('20260501141746'),
('20260424105720'),
('20260328185530'),
('20260227123031'),
('20260210135328'),
('20260210092444'),
('20260122093440'),
('20260121170436'),
('20260121170411'),
('20251229150246'),
('20251226102461'),
('20251226102460'),
('20251226102459'),
('20251213182025'),
('20251128215525'),
('20251118171856'),
('20251118000000'),
('20251114160144'),
('20251027105858'),
('20251025165300'),
('20251022171213'),
('20251021111854'),
('20251021083200'),
('20251020135223'),
('20251020123548'),
('20251017073059'),
('20251004142110'),
('20250925161849'),
('20250910125432'),
('20250910120000'),
('20250909101218'),
('20250717093710'),
('20250716064319'),
('20250715090801'),
('20250708140537'),
('20250610165558'),
('20250610121625'),
('20250609144952'),
('20250605200853'),
('20250605192922'),
('20250605190746'),
('20250522111247'),
('20250522105736'),
('20250522105410'),
('20250520103118'),
('20250518052059'),
('20250516065423'),
('20250515191606'),
('20250515191500'),
('20250515155551'),
('20250515072103'),
('20250515000136'),
('20250514113116'),
('20250514085552'),
('20250512170034'),
('20250512072300'),
('20250511124010'),
('20250511123651'),
('20250510115550'),
('20250510114223'),
('20250510114141'),
('20250510095126'),
('20250510002751'),
('20250509230101'),
('20250509170228'),
('20250509084443'),
('20250508170305'),
('20250508151724'),
('20250508082624'),
('20250507214604'),
('20250507173456'),
('20250507161237'),
('20250507154140'),
('20250507082225'),
('20250506192830'),
('20250506143910'),
('20250505201144'),
('20250504104256'),
('20250503192457'),
('20250503192449'),
('20250503192403'),
('20250430053948'),
('20250430053942'),
('20250425093137'),
('20250424201242'),
('20250424195410'),
('20250424194431'),
('20250424194230'),
('20250424162554'),
('20250424162524'),
('20250424161833'),
('20250424161825'),
('20250424161756'),
('20250424161603'),
('20250424161557'),
('20250424161519'),
('20250424082339'),
('20250424082256'),
('20250424072330'),
('20250423154408'),
('20250415181958'),
('20250415104938'),
('20250415070745'),
('20250415070735'),
('20250415070636'),
('20250414150254'),
('20250414135621'),
('20250414110651'),
('20250414103732'),
('20250411183534'),
('20250410092823'),
('20250410092211'),
('20250409202804'),
('20250409193040'),
('20250408150724'),
('20250407140405'),
('20250405062328'),
('20250404093651'),
('20250403124709'),
('20250403112944'),
('20250402140951'),
('20250401094510'),
('20250331190007'),
('20250331152058'),
('20250331130326'),
('20250331130122'),
('20250331101100'),
('20250329152643'),
('20250328152254'),
('20250328134318'),
('20250328095330'),
('20250328085258'),
('20250328063706'),
('20250327210325'),
('20250326052916'),
('20250326052125'),
('20250326051930'),
('20250325165114'),
('20250321160436'),
('20250321160400'),
('20250321101726'),
('20250319203813'),
('20250318134733'),
('20250318113335'),
('20250313121252'),
('20250313120053'),
('20250313115828'),
('20250312142328'),
('20250312135218'),
('20250312135125'),
('20250310150122'),
('20250310145945'),
('20250306153107'),
('20250306142824'),
('20250305153541'),
('20250305120443'),
('20250305111441'),
('20250305105906'),
('20250305095548'),
('20250227132619'),
('20250227132100'),
('20250227131913'),
('20250227125905'),
('20250227125412'),
('20250227090730'),
('20250226151727'),
('20250226151721'),
('20250226151716'),
('20250225134900'),
('20250225121525'),
('20250225121517'),
('20250218144430'),
('20250218144422'),
('20250218144415'),
('20250218144403'),
('20250218144347'),
('20250218144331'),
('20250218144311'),
('20250218144305'),
('20250218144300'),
('20250218144255'),
('20250218144236'),
('20250218143859'),
('20250218143851'),
('20250218143823'),
('20250218143811'),
('20250218143659'),
('20250218142519'),
('20250214104552'),
('20250213092809'),
('20250213074949'),
('20250211091245'),
('20250206092153'),
('20250204103627'),
('20250128161317'),
('20250128142955'),
('20250128131456'),
('20250128130650'),
('20250128121606'),
('20250128112655'),
('20250128105716'),
('20250128101339'),
('20250127000000'),
('20250118093741'),
('20250116194129'),
('20250116162955'),
('20250115223007'),
('20250114121522'),
('20250109101324'),
('20250109101028'),
('20241212160251'),
('20241212155655'),
('20241212154437'),
('20241212151349'),
('20241210160326'),
('20241210155846'),
('20241210153938'),
('20241210152129'),
('20241203182619'),
('20241127170723'),
('20241126133749'),
('20241119141626'),
('20241119122607'),
('20241118153059'),
('20241110200201'),
('20241110181500'),
('20241109230325'),
('20241105222339'),
('20241105220353'),
('20241105204845'),
('20241105204523'),
('20241105162810'),
('20241105160002'),
('20241105152854'),
('20241105133544'),
('20241105085921');

