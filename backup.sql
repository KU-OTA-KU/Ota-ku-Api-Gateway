--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Drop databases (except postgres and template1)
--

DROP DATABASE kong;




--
-- Drop roles
--

DROP ROLE kong;


--
-- Roles
--

CREATE ROLE kong;
ALTER ROLE kong WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'md5e1976b1e5ca708df08dd8daa78a5a769';






--
-- Databases
--

--
-- Database "template1" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 13.16 (Debian 13.16-1.pgdg120+1)
-- Dumped by pg_dump version 13.16 (Debian 13.16-1.pgdg120+1)

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

UPDATE pg_catalog.pg_database SET datistemplate = false WHERE datname = 'template1';
DROP DATABASE template1;
--
-- Name: template1; Type: DATABASE; Schema: -; Owner: kong
--

CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE template1 OWNER TO kong;

\connect template1

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

--
-- Name: DATABASE template1; Type: COMMENT; Schema: -; Owner: kong
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: template1; Type: DATABASE PROPERTIES; Schema: -; Owner: kong
--

ALTER DATABASE template1 IS_TEMPLATE = true;


\connect template1

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

--
-- Name: DATABASE template1; Type: ACL; Schema: -; Owner: kong
--

REVOKE CONNECT,TEMPORARY ON DATABASE template1 FROM PUBLIC;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- Database "kong" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 13.16 (Debian 13.16-1.pgdg120+1)
-- Dumped by pg_dump version 13.16 (Debian 13.16-1.pgdg120+1)

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

--
-- Name: kong; Type: DATABASE; Schema: -; Owner: kong
--

CREATE DATABASE kong WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE kong OWNER TO kong;

\connect kong

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

--
-- Name: batch_delete_expired_rows(); Type: FUNCTION; Schema: public; Owner: kong
--

CREATE FUNCTION public.batch_delete_expired_rows() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          EXECUTE FORMAT('WITH rows AS (SELECT ctid FROM %s WHERE %s < CURRENT_TIMESTAMP AT TIME ZONE ''UTC'' ORDER BY %s LIMIT 2 FOR UPDATE SKIP LOCKED) DELETE FROM %s WHERE ctid IN (TABLE rows)', TG_TABLE_NAME, TG_ARGV[0], TG_ARGV[0], TG_TABLE_NAME);
          RETURN NULL;
        END;
      $$;


ALTER FUNCTION public.batch_delete_expired_rows() OWNER TO kong;

--
-- Name: sync_tags(); Type: FUNCTION; Schema: public; Owner: kong
--

CREATE FUNCTION public.sync_tags() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          IF (TG_OP = 'TRUNCATE') THEN
            DELETE FROM tags WHERE entity_name = TG_TABLE_NAME;
            RETURN NULL;
          ELSIF (TG_OP = 'DELETE') THEN
            DELETE FROM tags WHERE entity_id = OLD.id;
            RETURN OLD;
          ELSE

          -- Triggered by INSERT/UPDATE
          -- Do an upsert on the tags table
          -- So we don't need to migrate pre 1.1 entities
          INSERT INTO tags VALUES (NEW.id, TG_TABLE_NAME, NEW.tags)
          ON CONFLICT (entity_id) DO UPDATE
                  SET tags=EXCLUDED.tags;
          END IF;
          RETURN NEW;
        END;
      $$;


ALTER FUNCTION public.sync_tags() OWNER TO kong;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acls; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.acls (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid,
    "group" text,
    cache_key text,
    tags text[],
    ws_id uuid
);


ALTER TABLE public.acls OWNER TO kong;

--
-- Name: acme_storage; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.acme_storage (
    id uuid NOT NULL,
    key text,
    value text,
    created_at timestamp with time zone,
    ttl timestamp with time zone
);


ALTER TABLE public.acme_storage OWNER TO kong;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.admins (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    updated_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid,
    rbac_user_id uuid,
    rbac_token_enabled boolean NOT NULL,
    email text,
    status integer,
    username text,
    custom_id text,
    username_lower text
);


ALTER TABLE public.admins OWNER TO kong;

--
-- Name: application_instances; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.application_instances (
    id uuid NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status integer,
    service_id uuid,
    application_id uuid,
    composite_id text,
    suspended boolean NOT NULL,
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid
);


ALTER TABLE public.application_instances OWNER TO kong;

--
-- Name: applications; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.applications (
    id uuid NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name text,
    description text,
    redirect_uri text,
    meta text,
    developer_id uuid,
    consumer_id uuid,
    custom_id text,
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid
);


ALTER TABLE public.applications OWNER TO kong;

--
-- Name: audit_objects; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.audit_objects (
    id uuid NOT NULL,
    request_id character(32),
    entity_key uuid,
    dao_name text NOT NULL,
    operation character(6) NOT NULL,
    entity text,
    rbac_user_id uuid,
    signature text,
    ttl timestamp with time zone DEFAULT (timezone('utc'::text, CURRENT_TIMESTAMP(0)) + '720:00:00'::interval),
    removed_from_entity text,
    request_timestamp timestamp without time zone DEFAULT timezone('utc'::text, CURRENT_TIMESTAMP(3))
);


ALTER TABLE public.audit_objects OWNER TO kong;

--
-- Name: audit_requests; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.audit_requests (
    request_id character(32) NOT NULL,
    request_timestamp timestamp without time zone DEFAULT timezone('utc'::text, CURRENT_TIMESTAMP(3)),
    client_ip text NOT NULL,
    path text NOT NULL,
    method text NOT NULL,
    payload text,
    status integer NOT NULL,
    rbac_user_id uuid,
    workspace uuid,
    signature text,
    ttl timestamp with time zone DEFAULT (timezone('utc'::text, CURRENT_TIMESTAMP(0)) + '720:00:00'::interval),
    removed_from_payload text,
    rbac_user_name text,
    request_source text
);


ALTER TABLE public.audit_requests OWNER TO kong;

--
-- Name: basicauth_credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.basicauth_credentials (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid,
    username text,
    password text,
    tags text[],
    ws_id uuid
);


ALTER TABLE public.basicauth_credentials OWNER TO kong;

--
-- Name: ca_certificates; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.ca_certificates (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    cert text NOT NULL,
    tags text[],
    cert_digest text NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.ca_certificates OWNER TO kong;

--
-- Name: certificates; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.certificates (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    cert text,
    key text,
    tags text[],
    ws_id uuid,
    cert_alt text,
    key_alt text,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.certificates OWNER TO kong;

--
-- Name: cluster_events; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.cluster_events (
    id uuid NOT NULL,
    node_id uuid NOT NULL,
    at timestamp with time zone NOT NULL,
    nbf timestamp with time zone,
    expire_at timestamp with time zone NOT NULL,
    channel text,
    data text
);


ALTER TABLE public.cluster_events OWNER TO kong;

--
-- Name: clustering_data_planes; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.clustering_data_planes (
    id uuid NOT NULL,
    hostname text NOT NULL,
    ip text NOT NULL,
    last_seen timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    config_hash text NOT NULL,
    ttl timestamp with time zone,
    version text,
    sync_status text DEFAULT 'unknown'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    labels jsonb,
    cert_details jsonb,
    rpc_capabilities text[]
);


ALTER TABLE public.clustering_data_planes OWNER TO kong;

--
-- Name: clustering_rpc_requests; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.clustering_rpc_requests (
    id bigint NOT NULL,
    node_id uuid NOT NULL,
    reply_to uuid NOT NULL,
    ttl timestamp with time zone NOT NULL,
    payload json NOT NULL
);


ALTER TABLE public.clustering_rpc_requests OWNER TO kong;

--
-- Name: clustering_rpc_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: kong
--

CREATE SEQUENCE public.clustering_rpc_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clustering_rpc_requests_id_seq OWNER TO kong;

--
-- Name: clustering_rpc_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kong
--

ALTER SEQUENCE public.clustering_rpc_requests_id_seq OWNED BY public.clustering_rpc_requests.id;


--
-- Name: consumer_group_consumers; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.consumer_group_consumers (
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_group_id uuid NOT NULL,
    consumer_id uuid NOT NULL,
    cache_key text,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.consumer_group_consumers OWNER TO kong;

--
-- Name: consumer_group_plugins; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.consumer_group_plugins (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_group_id uuid,
    name text NOT NULL,
    cache_key text,
    config jsonb NOT NULL,
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.consumer_group_plugins OWNER TO kong;

--
-- Name: consumer_groups; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.consumer_groups (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    name text,
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid,
    tags text[],
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.consumer_groups OWNER TO kong;

--
-- Name: consumer_reset_secrets; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.consumer_reset_secrets (
    id uuid NOT NULL,
    consumer_id uuid,
    secret text,
    status integer,
    client_addr text,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, CURRENT_TIMESTAMP(0)),
    updated_at timestamp without time zone DEFAULT timezone('utc'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.consumer_reset_secrets OWNER TO kong;

--
-- Name: consumers; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.consumers (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    username text,
    custom_id text,
    tags text[],
    ws_id uuid,
    username_lower text,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    type integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.consumers OWNER TO kong;

--
-- Name: credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.credentials (
    id uuid NOT NULL,
    consumer_id uuid,
    consumer_type integer,
    plugin text NOT NULL,
    credential_data json,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, ('now'::text)::timestamp(0) with time zone),
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.credentials OWNER TO kong;

--
-- Name: degraphql_routes; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.degraphql_routes (
    id uuid NOT NULL,
    service_id uuid,
    methods text[],
    uri text,
    query text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.degraphql_routes OWNER TO kong;

--
-- Name: developers; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.developers (
    id uuid NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    email text,
    status integer,
    meta text,
    custom_id text,
    consumer_id uuid,
    rbac_user_id uuid,
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid
);


ALTER TABLE public.developers OWNER TO kong;

--
-- Name: document_objects; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.document_objects (
    id uuid NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    service_id uuid,
    path text,
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid
);


ALTER TABLE public.document_objects OWNER TO kong;

--
-- Name: event_hooks; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.event_hooks (
    id uuid,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    source text NOT NULL,
    event text,
    handler text NOT NULL,
    on_change boolean,
    snooze integer,
    config json NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.event_hooks OWNER TO kong;

--
-- Name: files; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.files (
    id uuid NOT NULL,
    path text NOT NULL,
    checksum text,
    contents text,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, CURRENT_TIMESTAMP(0)),
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.files OWNER TO kong;

--
-- Name: filter_chains; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.filter_chains (
    id uuid NOT NULL,
    name text,
    enabled boolean DEFAULT true,
    route_id uuid,
    service_id uuid,
    ws_id uuid,
    cache_key text,
    filters jsonb[],
    tags text[],
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.filter_chains OWNER TO kong;

--
-- Name: graphql_ratelimiting_advanced_cost_decoration; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.graphql_ratelimiting_advanced_cost_decoration (
    id uuid NOT NULL,
    service_id uuid,
    type_path text,
    add_arguments text[],
    add_constant double precision,
    mul_arguments text[],
    mul_constant double precision,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.graphql_ratelimiting_advanced_cost_decoration OWNER TO kong;

--
-- Name: group_rbac_roles; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.group_rbac_roles (
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    group_id uuid NOT NULL,
    rbac_role_id uuid NOT NULL,
    workspace_id uuid,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.group_rbac_roles OWNER TO kong;

--
-- Name: groups; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.groups (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    name text,
    comment text,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.groups OWNER TO kong;

--
-- Name: header_cert_auth_credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.header_cert_auth_credentials (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid NOT NULL,
    subject_name text NOT NULL,
    ca_certificate_id uuid,
    cache_key text,
    tags text[],
    ws_id uuid
);


ALTER TABLE public.header_cert_auth_credentials OWNER TO kong;

--
-- Name: hmacauth_credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.hmacauth_credentials (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid,
    username text,
    secret text,
    tags text[],
    ws_id uuid
);


ALTER TABLE public.hmacauth_credentials OWNER TO kong;

--
-- Name: jwt_secrets; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.jwt_secrets (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid,
    key text,
    secret text,
    algorithm text,
    rsa_public_key text,
    tags text[],
    ws_id uuid
);


ALTER TABLE public.jwt_secrets OWNER TO kong;

--
-- Name: jwt_signer_jwks; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.jwt_signer_jwks (
    id uuid NOT NULL,
    name text NOT NULL,
    keys jsonb[] NOT NULL,
    previous jsonb[],
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.jwt_signer_jwks OWNER TO kong;

--
-- Name: key_sets; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.key_sets (
    id uuid NOT NULL,
    name text,
    tags text[],
    ws_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.key_sets OWNER TO kong;

--
-- Name: keyauth_credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.keyauth_credentials (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid,
    key text,
    tags text[],
    ttl timestamp with time zone,
    ws_id uuid
);


ALTER TABLE public.keyauth_credentials OWNER TO kong;

--
-- Name: keyauth_enc_credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.keyauth_enc_credentials (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid,
    key text,
    key_ident text,
    ws_id uuid,
    tags text[],
    ttl timestamp with time zone
);


ALTER TABLE public.keyauth_enc_credentials OWNER TO kong;

--
-- Name: keyring_keys; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.keyring_keys (
    id text NOT NULL,
    recovery_key_id text NOT NULL,
    key_encrypted text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.keyring_keys OWNER TO kong;

--
-- Name: keyring_meta; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.keyring_meta (
    id text NOT NULL,
    state text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.keyring_meta OWNER TO kong;

--
-- Name: keys; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.keys (
    id uuid NOT NULL,
    set_id uuid,
    name text,
    cache_key text,
    ws_id uuid,
    kid text,
    jwk text,
    pem jsonb,
    tags text[],
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.keys OWNER TO kong;

--
-- Name: konnect_applications; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.konnect_applications (
    id uuid NOT NULL,
    ws_id uuid,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    client_id text,
    scopes text[],
    tags text[],
    consumer_groups text[],
    auth_strategy_id text,
    application_context jsonb,
    exhausted_scopes text[]
);


ALTER TABLE public.konnect_applications OWNER TO kong;

--
-- Name: legacy_files; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.legacy_files (
    id uuid NOT NULL,
    auth boolean NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    contents text,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, CURRENT_TIMESTAMP(0)),
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.legacy_files OWNER TO kong;

--
-- Name: license_data; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.license_data (
    node_id uuid NOT NULL,
    req_cnt bigint,
    license_creation_date timestamp without time zone,
    year smallint NOT NULL,
    month smallint NOT NULL
);


ALTER TABLE public.license_data OWNER TO kong;

--
-- Name: licenses; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.licenses (
    id uuid NOT NULL,
    payload text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    checksum text
);


ALTER TABLE public.licenses OWNER TO kong;

--
-- Name: locks; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.locks (
    key text NOT NULL,
    owner text,
    ttl timestamp with time zone
);


ALTER TABLE public.locks OWNER TO kong;

--
-- Name: login_attempts; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.login_attempts (
    consumer_id uuid NOT NULL,
    attempts json DEFAULT '{}'::json,
    ttl timestamp with time zone,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    attempt_type text DEFAULT 'login'::text NOT NULL
);


ALTER TABLE public.login_attempts OWNER TO kong;

--
-- Name: mtls_auth_credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.mtls_auth_credentials (
    id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    consumer_id uuid NOT NULL,
    subject_name text NOT NULL,
    ca_certificate_id uuid,
    cache_key text,
    ws_id uuid,
    tags text[]
);


ALTER TABLE public.mtls_auth_credentials OWNER TO kong;

--
-- Name: oauth2_authorization_codes; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.oauth2_authorization_codes (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    credential_id uuid,
    service_id uuid,
    code text,
    authenticated_userid text,
    scope text,
    ttl timestamp with time zone,
    challenge text,
    challenge_method text,
    ws_id uuid,
    plugin_id uuid
);


ALTER TABLE public.oauth2_authorization_codes OWNER TO kong;

--
-- Name: oauth2_credentials; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.oauth2_credentials (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    name text,
    consumer_id uuid,
    client_id text,
    client_secret text,
    redirect_uris text[],
    tags text[],
    client_type text,
    hash_secret boolean,
    ws_id uuid
);


ALTER TABLE public.oauth2_credentials OWNER TO kong;

--
-- Name: oauth2_tokens; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.oauth2_tokens (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    credential_id uuid,
    service_id uuid,
    access_token text,
    refresh_token text,
    token_type text,
    expires_in integer,
    authenticated_userid text,
    scope text,
    ttl timestamp with time zone,
    ws_id uuid
);


ALTER TABLE public.oauth2_tokens OWNER TO kong;

--
-- Name: oic_issuers; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.oic_issuers (
    id uuid NOT NULL,
    issuer text,
    configuration text,
    keys text,
    secret text,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.oic_issuers OWNER TO kong;

--
-- Name: oic_jwks; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.oic_jwks (
    id uuid NOT NULL,
    jwks jsonb
);


ALTER TABLE public.oic_jwks OWNER TO kong;

--
-- Name: parameters; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.parameters (
    key text NOT NULL,
    value text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.parameters OWNER TO kong;

--
-- Name: plugins; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.plugins (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    name text NOT NULL,
    consumer_id uuid,
    service_id uuid,
    route_id uuid,
    config jsonb NOT NULL,
    enabled boolean NOT NULL,
    cache_key text,
    protocols text[],
    tags text[],
    ws_id uuid,
    instance_name text,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    ordering jsonb,
    consumer_group_id uuid
);


ALTER TABLE public.plugins OWNER TO kong;

--
-- Name: ratelimiting_metrics; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.ratelimiting_metrics (
    identifier text NOT NULL,
    period text NOT NULL,
    period_date timestamp with time zone NOT NULL,
    service_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    route_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    value integer,
    ttl timestamp with time zone
);


ALTER TABLE public.ratelimiting_metrics OWNER TO kong;

--
-- Name: rbac_role_endpoints; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.rbac_role_endpoints (
    role_id uuid NOT NULL,
    workspace text NOT NULL,
    endpoint text NOT NULL,
    actions smallint NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    negative boolean NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.rbac_role_endpoints OWNER TO kong;

--
-- Name: rbac_role_entities; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.rbac_role_entities (
    role_id uuid NOT NULL,
    entity_id text NOT NULL,
    entity_type text NOT NULL,
    actions smallint NOT NULL,
    negative boolean NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.rbac_role_entities OWNER TO kong;

--
-- Name: rbac_roles; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.rbac_roles (
    id uuid NOT NULL,
    name text NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    is_default boolean DEFAULT false,
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.rbac_roles OWNER TO kong;

--
-- Name: rbac_user_groups; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.rbac_user_groups (
    user_id uuid NOT NULL,
    group_id uuid NOT NULL
);


ALTER TABLE public.rbac_user_groups OWNER TO kong;

--
-- Name: rbac_user_roles; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.rbac_user_roles (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    role_source text
);


ALTER TABLE public.rbac_user_roles OWNER TO kong;

--
-- Name: rbac_users; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.rbac_users (
    id uuid NOT NULL,
    name text NOT NULL,
    user_token text NOT NULL,
    user_token_ident text,
    comment text,
    enabled boolean NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    ws_id uuid DEFAULT '5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c'::uuid,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.rbac_users OWNER TO kong;

--
-- Name: response_ratelimiting_metrics; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.response_ratelimiting_metrics (
    identifier text NOT NULL,
    period text NOT NULL,
    period_date timestamp with time zone NOT NULL,
    service_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    route_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    value integer
);


ALTER TABLE public.response_ratelimiting_metrics OWNER TO kong;

--
-- Name: rl_counters; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.rl_counters (
    key text NOT NULL,
    namespace text NOT NULL,
    window_start integer NOT NULL,
    window_size integer NOT NULL,
    count integer
);


ALTER TABLE public.rl_counters OWNER TO kong;

--
-- Name: routes; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.routes (
    id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name text,
    service_id uuid,
    protocols text[],
    methods text[],
    hosts text[],
    paths text[],
    snis text[],
    sources jsonb[],
    destinations jsonb[],
    regex_priority bigint,
    strip_path boolean,
    preserve_host boolean,
    tags text[],
    https_redirect_status_code integer,
    headers jsonb,
    path_handling text DEFAULT 'v0'::text,
    ws_id uuid,
    request_buffering boolean,
    response_buffering boolean,
    expression text,
    priority bigint
);


ALTER TABLE public.routes OWNER TO kong;

--
-- Name: schema_meta; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.schema_meta (
    key text NOT NULL,
    subsystem text NOT NULL,
    last_executed text,
    executed text[],
    pending text[]
);


ALTER TABLE public.schema_meta OWNER TO kong;

--
-- Name: services; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.services (
    id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name text,
    retries bigint,
    protocol text,
    host text,
    port bigint,
    path text,
    connect_timeout bigint,
    write_timeout bigint,
    read_timeout bigint,
    tags text[],
    client_certificate_id uuid,
    tls_verify boolean,
    tls_verify_depth smallint,
    ca_certificates uuid[],
    ws_id uuid,
    enabled boolean DEFAULT true
);


ALTER TABLE public.services OWNER TO kong;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.sessions (
    id uuid NOT NULL,
    session_id text,
    expires integer,
    data text,
    created_at timestamp with time zone,
    ttl timestamp with time zone
);


ALTER TABLE public.sessions OWNER TO kong;

--
-- Name: sm_vaults; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.sm_vaults (
    id uuid NOT NULL,
    ws_id uuid,
    prefix text,
    name text NOT NULL,
    description text,
    config jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    updated_at timestamp with time zone,
    tags text[]
);


ALTER TABLE public.sm_vaults OWNER TO kong;

--
-- Name: snis; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.snis (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    name text NOT NULL,
    certificate_id uuid,
    tags text[],
    ws_id uuid,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.snis OWNER TO kong;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.tags (
    entity_id uuid NOT NULL,
    entity_name text,
    tags text[]
);


ALTER TABLE public.tags OWNER TO kong;

--
-- Name: targets; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.targets (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(3)),
    upstream_id uuid,
    target text NOT NULL,
    weight integer NOT NULL,
    tags text[],
    ws_id uuid,
    cache_key text,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(3))
);


ALTER TABLE public.targets OWNER TO kong;

--
-- Name: upstreams; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.upstreams (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(3)),
    name text,
    hash_on text,
    hash_fallback text,
    hash_on_header text,
    hash_fallback_header text,
    hash_on_cookie text,
    hash_on_cookie_path text,
    slots integer NOT NULL,
    healthchecks jsonb,
    tags text[],
    algorithm text,
    host_header text,
    client_certificate_id uuid,
    ws_id uuid,
    hash_on_query_arg text,
    hash_fallback_query_arg text,
    hash_on_uri_capture text,
    hash_fallback_uri_capture text,
    use_srv_name boolean DEFAULT false,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.upstreams OWNER TO kong;

--
-- Name: vault_auth_vaults; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vault_auth_vaults (
    id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name text,
    protocol text,
    host text,
    port bigint,
    mount text,
    vault_token text,
    kv text
);


ALTER TABLE public.vault_auth_vaults OWNER TO kong;

--
-- Name: vaults; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vaults (
    id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name text,
    protocol text,
    host text,
    port bigint,
    mount text,
    vault_token text
);


ALTER TABLE public.vaults OWNER TO kong;

--
-- Name: vitals_code_classes_by_cluster; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_code_classes_by_cluster (
    code_class integer NOT NULL,
    at timestamp with time zone NOT NULL,
    duration integer NOT NULL,
    count integer
);


ALTER TABLE public.vitals_code_classes_by_cluster OWNER TO kong;

--
-- Name: vitals_code_classes_by_workspace; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_code_classes_by_workspace (
    workspace_id uuid NOT NULL,
    code_class integer NOT NULL,
    at timestamp with time zone NOT NULL,
    duration integer NOT NULL,
    count integer
);


ALTER TABLE public.vitals_code_classes_by_workspace OWNER TO kong;

--
-- Name: vitals_codes_by_consumer_route; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_codes_by_consumer_route (
    consumer_id uuid NOT NULL,
    service_id uuid,
    route_id uuid NOT NULL,
    code integer NOT NULL,
    at timestamp with time zone NOT NULL,
    duration integer NOT NULL,
    count integer
)
WITH (autovacuum_vacuum_scale_factor='0.01', autovacuum_analyze_scale_factor='0.01');


ALTER TABLE public.vitals_codes_by_consumer_route OWNER TO kong;

--
-- Name: vitals_codes_by_route; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_codes_by_route (
    service_id uuid,
    route_id uuid NOT NULL,
    code integer NOT NULL,
    at timestamp with time zone NOT NULL,
    duration integer NOT NULL,
    count integer
)
WITH (autovacuum_vacuum_scale_factor='0.01', autovacuum_analyze_scale_factor='0.01');


ALTER TABLE public.vitals_codes_by_route OWNER TO kong;

--
-- Name: vitals_locks; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_locks (
    key text NOT NULL,
    expiry timestamp with time zone
);


ALTER TABLE public.vitals_locks OWNER TO kong;

--
-- Name: vitals_node_meta; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_node_meta (
    node_id uuid NOT NULL,
    first_report timestamp without time zone,
    last_report timestamp without time zone,
    hostname text
);


ALTER TABLE public.vitals_node_meta OWNER TO kong;

--
-- Name: vitals_stats_days; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_stats_days (
    node_id uuid NOT NULL,
    at integer NOT NULL,
    l2_hit integer DEFAULT 0,
    l2_miss integer DEFAULT 0,
    plat_min integer,
    plat_max integer,
    ulat_min integer,
    ulat_max integer,
    requests integer DEFAULT 0,
    plat_count integer DEFAULT 0,
    plat_total integer DEFAULT 0,
    ulat_count integer DEFAULT 0,
    ulat_total integer DEFAULT 0
);


ALTER TABLE public.vitals_stats_days OWNER TO kong;

--
-- Name: vitals_stats_hours; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_stats_hours (
    at integer NOT NULL,
    l2_hit integer DEFAULT 0,
    l2_miss integer DEFAULT 0,
    plat_min integer,
    plat_max integer
);


ALTER TABLE public.vitals_stats_hours OWNER TO kong;

--
-- Name: vitals_stats_minutes; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_stats_minutes (
    node_id uuid NOT NULL,
    at integer NOT NULL,
    l2_hit integer DEFAULT 0,
    l2_miss integer DEFAULT 0,
    plat_min integer,
    plat_max integer,
    ulat_min integer,
    ulat_max integer,
    requests integer DEFAULT 0,
    plat_count integer DEFAULT 0,
    plat_total integer DEFAULT 0,
    ulat_count integer DEFAULT 0,
    ulat_total integer DEFAULT 0
);


ALTER TABLE public.vitals_stats_minutes OWNER TO kong;

--
-- Name: vitals_stats_seconds; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.vitals_stats_seconds (
    node_id uuid NOT NULL,
    at integer NOT NULL,
    l2_hit integer DEFAULT 0,
    l2_miss integer DEFAULT 0,
    plat_min integer,
    plat_max integer,
    ulat_min integer,
    ulat_max integer,
    requests integer DEFAULT 0,
    plat_count integer DEFAULT 0,
    plat_total integer DEFAULT 0,
    ulat_count integer DEFAULT 0,
    ulat_total integer DEFAULT 0
);


ALTER TABLE public.vitals_stats_seconds OWNER TO kong;

--
-- Name: workspace_entities; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.workspace_entities (
    workspace_id uuid NOT NULL,
    workspace_name text,
    entity_id text NOT NULL,
    entity_type text,
    unique_field_name text NOT NULL,
    unique_field_value text
);


ALTER TABLE public.workspace_entities OWNER TO kong;

--
-- Name: workspace_entity_counters; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.workspace_entity_counters (
    workspace_id uuid NOT NULL,
    entity_type text NOT NULL,
    count integer
);


ALTER TABLE public.workspace_entity_counters OWNER TO kong;

--
-- Name: workspaces; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.workspaces (
    id uuid NOT NULL,
    name text,
    comment text,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0)),
    meta jsonb,
    config jsonb,
    updated_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.workspaces OWNER TO kong;

--
-- Name: ws_migrations_backup; Type: TABLE; Schema: public; Owner: kong
--

CREATE TABLE public.ws_migrations_backup (
    entity_type text,
    entity_id text,
    unique_field_name text,
    unique_field_value text,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP(0))
);


ALTER TABLE public.ws_migrations_backup OWNER TO kong;

--
-- Name: clustering_rpc_requests id; Type: DEFAULT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.clustering_rpc_requests ALTER COLUMN id SET DEFAULT nextval('public.clustering_rpc_requests_id_seq'::regclass);


--
-- Data for Name: acls; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.acls (id, created_at, consumer_id, "group", cache_key, tags, ws_id) FROM stdin;
\.


--
-- Data for Name: acme_storage; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.acme_storage (id, key, value, created_at, ttl) FROM stdin;
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.admins (id, created_at, updated_at, consumer_id, rbac_user_id, rbac_token_enabled, email, status, username, custom_id, username_lower) FROM stdin;
\.


--
-- Data for Name: application_instances; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.application_instances (id, created_at, updated_at, status, service_id, application_id, composite_id, suspended, ws_id) FROM stdin;
\.


--
-- Data for Name: applications; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.applications (id, created_at, updated_at, name, description, redirect_uri, meta, developer_id, consumer_id, custom_id, ws_id) FROM stdin;
\.


--
-- Data for Name: audit_objects; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.audit_objects (id, request_id, entity_key, dao_name, operation, entity, rbac_user_id, signature, ttl, removed_from_entity, request_timestamp) FROM stdin;
\.


--
-- Data for Name: audit_requests; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.audit_requests (request_id, request_timestamp, client_ip, path, method, payload, status, rbac_user_id, workspace, signature, ttl, removed_from_payload, rbac_user_name, request_source) FROM stdin;
\.


--
-- Data for Name: basicauth_credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.basicauth_credentials (id, created_at, consumer_id, username, password, tags, ws_id) FROM stdin;
\.


--
-- Data for Name: ca_certificates; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.ca_certificates (id, created_at, cert, tags, cert_digest, updated_at) FROM stdin;
\.


--
-- Data for Name: certificates; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.certificates (id, created_at, cert, key, tags, ws_id, cert_alt, key_alt, updated_at) FROM stdin;
\.


--
-- Data for Name: cluster_events; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.cluster_events (id, node_id, at, nbf, expire_at, channel, data) FROM stdin;
\.


--
-- Data for Name: clustering_data_planes; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.clustering_data_planes (id, hostname, ip, last_seen, config_hash, ttl, version, sync_status, updated_at, labels, cert_details, rpc_capabilities) FROM stdin;
\.


--
-- Data for Name: clustering_rpc_requests; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.clustering_rpc_requests (id, node_id, reply_to, ttl, payload) FROM stdin;
\.


--
-- Data for Name: consumer_group_consumers; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.consumer_group_consumers (created_at, consumer_group_id, consumer_id, cache_key, updated_at) FROM stdin;
\.


--
-- Data for Name: consumer_group_plugins; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.consumer_group_plugins (id, created_at, consumer_group_id, name, cache_key, config, ws_id, updated_at) FROM stdin;
\.


--
-- Data for Name: consumer_groups; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.consumer_groups (id, created_at, name, ws_id, tags, updated_at) FROM stdin;
\.


--
-- Data for Name: consumer_reset_secrets; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.consumer_reset_secrets (id, consumer_id, secret, status, client_addr, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: consumers; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.consumers (id, created_at, username, custom_id, tags, ws_id, username_lower, updated_at, type) FROM stdin;
\.


--
-- Data for Name: credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.credentials (id, consumer_id, consumer_type, plugin, credential_data, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: degraphql_routes; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.degraphql_routes (id, service_id, methods, uri, query, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: developers; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.developers (id, created_at, updated_at, email, status, meta, custom_id, consumer_id, rbac_user_id, ws_id) FROM stdin;
\.


--
-- Data for Name: document_objects; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.document_objects (id, created_at, updated_at, service_id, path, ws_id) FROM stdin;
\.


--
-- Data for Name: event_hooks; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.event_hooks (id, created_at, source, event, handler, on_change, snooze, config, updated_at) FROM stdin;
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.files (id, path, checksum, contents, created_at, ws_id, updated_at) FROM stdin;
\.


--
-- Data for Name: filter_chains; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.filter_chains (id, name, enabled, route_id, service_id, ws_id, cache_key, filters, tags, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: graphql_ratelimiting_advanced_cost_decoration; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.graphql_ratelimiting_advanced_cost_decoration (id, service_id, type_path, add_arguments, add_constant, mul_arguments, mul_constant, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: group_rbac_roles; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.group_rbac_roles (created_at, group_id, rbac_role_id, workspace_id, updated_at) FROM stdin;
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.groups (id, created_at, name, comment, updated_at) FROM stdin;
\.


--
-- Data for Name: header_cert_auth_credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.header_cert_auth_credentials (id, created_at, consumer_id, subject_name, ca_certificate_id, cache_key, tags, ws_id) FROM stdin;
\.


--
-- Data for Name: hmacauth_credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.hmacauth_credentials (id, created_at, consumer_id, username, secret, tags, ws_id) FROM stdin;
\.


--
-- Data for Name: jwt_secrets; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.jwt_secrets (id, created_at, consumer_id, key, secret, algorithm, rsa_public_key, tags, ws_id) FROM stdin;
\.


--
-- Data for Name: jwt_signer_jwks; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.jwt_signer_jwks (id, name, keys, previous, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: key_sets; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.key_sets (id, name, tags, ws_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: keyauth_credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.keyauth_credentials (id, created_at, consumer_id, key, tags, ttl, ws_id) FROM stdin;
\.


--
-- Data for Name: keyauth_enc_credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.keyauth_enc_credentials (id, created_at, consumer_id, key, key_ident, ws_id, tags, ttl) FROM stdin;
\.


--
-- Data for Name: keyring_keys; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.keyring_keys (id, recovery_key_id, key_encrypted, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: keyring_meta; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.keyring_meta (id, state, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: keys; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.keys (id, set_id, name, cache_key, ws_id, kid, jwk, pem, tags, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: konnect_applications; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.konnect_applications (id, ws_id, created_at, client_id, scopes, tags, consumer_groups, auth_strategy_id, application_context, exhausted_scopes) FROM stdin;
\.


--
-- Data for Name: legacy_files; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.legacy_files (id, auth, name, type, contents, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: license_data; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.license_data (node_id, req_cnt, license_creation_date, year, month) FROM stdin;
62b1282b-c37e-4789-9146-300f56450cde	0	2017-07-20 00:00:00	2024	9
049a961f-ab11-4df0-9b56-3818923bb827	1	2017-07-20 00:00:00	2024	9
\.


--
-- Data for Name: licenses; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.licenses (id, payload, created_at, updated_at, checksum) FROM stdin;
\.


--
-- Data for Name: locks; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.locks (key, owner, ttl) FROM stdin;
\.


--
-- Data for Name: login_attempts; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.login_attempts (consumer_id, attempts, ttl, created_at, updated_at, attempt_type) FROM stdin;
\.


--
-- Data for Name: mtls_auth_credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.mtls_auth_credentials (id, created_at, consumer_id, subject_name, ca_certificate_id, cache_key, ws_id, tags) FROM stdin;
\.


--
-- Data for Name: oauth2_authorization_codes; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.oauth2_authorization_codes (id, created_at, credential_id, service_id, code, authenticated_userid, scope, ttl, challenge, challenge_method, ws_id, plugin_id) FROM stdin;
\.


--
-- Data for Name: oauth2_credentials; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.oauth2_credentials (id, created_at, name, consumer_id, client_id, client_secret, redirect_uris, tags, client_type, hash_secret, ws_id) FROM stdin;
\.


--
-- Data for Name: oauth2_tokens; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.oauth2_tokens (id, created_at, credential_id, service_id, access_token, refresh_token, token_type, expires_in, authenticated_userid, scope, ttl, ws_id) FROM stdin;
\.


--
-- Data for Name: oic_issuers; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.oic_issuers (id, issuer, configuration, keys, secret, created_at) FROM stdin;
\.


--
-- Data for Name: oic_jwks; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.oic_jwks (id, jwks) FROM stdin;
c3cfba2d-1617-453f-a416-52e6edb5f9a0	{"keys": [{"k": "VeG3npo7ogtanX1mw9uE-FYj3p4ZqeUGIL-OXdre5gs", "alg": "HS256", "kid": "9VHclmDmbDtxUtzYd8q6k9zRx2gmA2lejedCpJqXVyw", "kty": "oct", "use": "sig"}, {"k": "_L_5oC47JRvUm2vn5pNLvJCVeeUS_mn2J58lAyEdLQmsJOsAmOIL2yz0u1Lw-F9A", "alg": "HS384", "kid": "oJCSgESeOHqivSwYC11XJ4dkrCB6He0UuOSU8xkrtuQ", "kty": "oct", "use": "sig"}, {"k": "mATmKbh0acZKbgaBCcrr9i0QRbDnvzsOspYRK0LHjfi2vVmx44kOyNqF_K2G3J4H8wnAwM0B0wQgB8280xRmcQ", "alg": "HS512", "kid": "Nx0AaLQV13Ds7t-VxQSQSnvyedgrU8vc4RpzPE9CuYQ", "kty": "oct", "use": "sig"}, {"d": "BQibCOxO4nFJWp5nFOD1_5DHn9Y7QMagCjEUNQICMP3mdKyL_1qq63nr65c0b8g3i1rH3o_AGr9FU6R72WnQ5sAQRA-6mtETJ9CC40j08SzCqH4HaNj7XUDyPpN9KaaIP-QEy5e2NulBReSPVq645ZnlmjuwTJSNWDbVD5kgdeqEhp7OrzPI35FEiVwKBdfJglmNd3naXoSg-2EE5hkClx1rbYaHIe21O2ZdYzpYKLTtUArLX4TWzCgl5_MJLKDLEtyeW74HxV5X_pYNBHznyNsEbwEqE50oJqzMmNjQKnfKiNcqZRwtbJUj20P8qRgfqYZP9TM1LYHKl4qX2DFz8Q", "e": "AQAB", "n": "3vKTGAzii3orPJHa2eMV8sFJhXuLy3-movCrwhlaFOSCx_HQWNAB_Fbc6NaKHnKl5ulujmF2mWlC_5BC_tiqV3r05CTovN-kV5oLYi-s3Jiu1-wk8g3DI_uHu1NnfDo65bDhFDb8A15SyG8r3yNlCYmjLDngyf6aWAk3nH4xi-mbQ2xdJuG8QguFlJrNtjIKdmiJjE07wPYs-5hU6b5m_GpRx_Mzp8gVqnZ-aGubsUusRLLZB18GtuQLI7zfNKrChPepN1nIC6zQI68kVeJpVDH49vbJICC0g_l_Ysr_VRdxgsZhccpFbU2k51Mnh1dMEAeiCp5DdrgHAGQborSOYQ", "p": "9SP5ajQ9TJdiwTcZEaxv8cCH4KZ5_KVB1J0spD85E2EtKgJqAlRUtXk5U6C5LD7cB-e6IPxScyisIsV7PAQRUwIjg1FaFUcr6t2bMcrsgE4XSkTT6ACrDfopSbVumGvLR-pLhCu0qCRfXLltNkmmqDed5N1vl8soM9AxSpOIOEU", "q": "6NLrixTRSndAE6tR-YkR95V0u2ezq3b_WIpdkgXURiXDFomfr4u1COsCF2pf5j1dPeNEmWxrCzkMWwAl4GD9mnpJ_R7aPSpyAu23-UE2kc88bWis_I4IDy6WQuMnhAtF4D6fj1Aiq757NfFfAX10Ef_dOjuvyZfJP2-pb6ICRW0", "dp": "yS20yswEYo76pMaq9C4n0KbI3DzDb-vPksVKlaCtHpJplkhU54R94FCUE2WbkgwkVvh9cASjRY7jdcXL1P0hmpXuvx5MZ5n5GM61Rq_aV5G-21yQ651gxB_BMpSLJtuQAHzvbJDRugvflyE114-qDfNWyTRRGKnJXHxHd4SMDmE", "dq": "os9kAXVESeOMPnTuNSaCFvU_lRGWlc_4De1sM4G6CHe9rdP9g9-ZcCwO4Vr0xuegfXeg7_zd-hIhrr0yv25zyYO8m7HogR9ebOfZYAcXZu1ZX1T0qwOTZTJ5xzpb1r2fVonUQH6UUC86r-UjP8J_2VpoVKGKctme1Kp7_OF43x0", "qi": "fQZ9FyBu-XnH8ADAldMyQXuBhB3YAolXcuGyWDJ2l_fk9b7yirWch6o6_FXOUjGgoTPDzvxN-s6OEQB_6k3JiGDPoqo8J7RCSJbHeBzaJXH2q0UMrtaHoMqiqWxWBt9erJWXLyvFkJ6-bI_t0cvEG2zL9DhRZ1uqfPkKdTaSnqQ", "alg": "RS256", "kid": "sC8puAhwJxV1_9QBMxAmizQ_NiDUY_dZxmUdo95BCbY", "kty": "RSA", "use": "sig"}, {"d": "uL8V-gVKdtkYy0owvwrXLaUJyB8IdiNAAFkdzDZcF0Xkiayx3abLQRZr2hedf5O_l96r2p6lh10eQ6EnTD9sORtOLjIbqqArZvkO7CZ4ic7Hja20KnXDmqu_8fF9tU0UA-lYwBII2UzPvwbSSCTTLnAaBSFsiVOG5K6Jyh-ou-l_1hy-bqIhr4jE7DkH-e8crJ_IAgToI9cpHD4inbgrmuu2aM9kfEdbCyrHDkRM1e8VWP3mujNPqjGPrE7ysWFnmHTq7-whX42yOh6lGjho_QX47sT-qOnRQnfQTF44E8BP5croV534hAKNM3kKoUb-_LibxcQwAqbBLz7QqSxz", "e": "AQAB", "n": "tCysWNm9LnWTZkoaXdmQEBO3ReKP7aMSLXG65noO7J_sT4wsaanY5gppREel4PrgeI6ki74sB8_eeqJL_2qEHcYAR65cg2XAowDvzndc1N-jtGDMpfNA6ns5pvQ8H_rqXZzg8z23wO-Tyy3m8dM-Pqvq_cnR1svi9P0B7Cpfb0DPau4T8A0R583yyv_-x_GEPsds3Va6C3_H9XOl3ZhjGsnx2yW9dbbguBD2Ch2s1KvBEAVguhuECJtQvb_geMsTKEYVWNFgBFSpITgsInXRd0AmUJmklbMtln_mK0QU9bpyJy7JAmzkOmZXSl1Vk7FQEOJZ84OxiOHQwcJL-bhK8Q", "p": "4TVovzR43FtxPZg8R-hdIcqdHYYJ9c0HVYQJ2rJj6GwcQ3QR1M_9jm1UNe2Cq0M7VgVoPltuipA_ao7-y3MHw6mlvKZpvI1qUnZxFC-FuFeKCioef_5a-fEyNeKMfNimV8QAOA4iXEC2pHn64CN5fmsX3veakywxUQAh0RgmK9M", "q": "zM8DDvW5sZR9bBjtsc2SWRVWPSub2BTIH5iEX4rri262Jgjx9_aAbMvvJktfqDvgpkGkNK-FcJSi3v-VFAvIF3Ebs39cW38GjX6VezTl2I36ajZWJ5X4po4bZHF__RqrX3vyx2-ifCSdl00w-P7HiywpeQoscvAbhE4PqFI4x6s", "dp": "Rv7DSqOMBkt9Y2F-f1ytH130Mb5znV1JFphNUvgxrq-GKW2JwYDf-epVRbreGodTSUbjGeVQ77WRiFIT2Kcmp3Pvn40GgD5EakKUWzyv9vEBvzqP6uGQZIK4xWvpxeG2bqyHNSSfiF2ONkON5uLIBiZUnCGKRSMFWPelsXjfb6k", "dq": "V0MAZ5hUtQ-yXKNGaxJOf3wy0T9KWEeKeMPP6rFS6IaUPyJijibN0w0U6PkGWbShY9Tl9LiwHyaFOoQk7XSTnUFI7zKdlDJMBW9gmy0PnTPo9OYP0S_50GUN0L73LEz3pWg3Kbgrv78OEhAGhKBxPp_jT7oA9DvPTZDA5RObM58", "qi": "xfoqjlesLMw2kfOsgfK6iNeBWg29jutBZ4BoIibio56XjMw4TzWwCJCkRJO-e_L2INg0tol0BI1z_jL3XhLlPOS1AoiQWH3GpGKfO7LqAEfxvyr5dbXPAptRzqDVMmy3uCkySmKx1nmvbkcvzxYZc1zT23wQ2pfwJMcWkD2qzlg", "alg": "RS384", "kid": "yhrGe5pOtiRgwtnVFgLN_ZA6DPe_CBEc980rNcOAnq8", "kty": "RSA", "use": "sig"}, {"d": "K1Co9xMVPlFKhkZB2z48HtXg-cwOweq5HpO2RksXm124MgQezgt6ES02zC6KNa21GSaUUszIotw3ZYGjQdaJ4fbRCIBSJ9mc5VZ2dH_Uo6U4iJCbqobFsQucuHlzqtk_pbOkxS34l813MjMYduWZsbFdT1HYUKI0AXq-TZuYw2NA2SC5YfjSe971dTg0HT9eiFcStsMLITeesF51lEgIs5Y7Lq_REnImddGBFW3nBN1UyvU5-5tvMM4ze7Uapz11RszpPNATUoTWYJPU1dRtIH2HCLlldjxThIFWVaVpbZFF-kN8GWhsiC2_gDDG-CPRj-VwqQ1QkpcDrtX69AdfFQ", "e": "AQAB", "n": "scKXZ4SiSKSdgmGMTKjbDwdUuW0OiALOUW66jDWKW-yo_WqHOGyPjE_dI89F_CKjcf8Dgj3y9iF98IwOIWuh-Qm02pUUJSe2LbFd5fyq-TmPgphfyOTbEhhpKW8JthkIGkdcDXpA3z4UDIItxGImB3ifOfocZdWcAydsddrlLDHsyOGXVTmkIVvPhCogjRRNBx9KmswXGYN52UfDxmZhwkM6H-klkV9sc8cDALKHOXKYeJmWoTJNuP5OmkzSdqAQCkc5zfj1wVWCmiAkl1bQ5x8P-INlD1L7V1SDukBYkP0wChjjCEabV8OrfWf8WEaHKifKp3CUQEPGnxFOmaxvkw", "p": "4ZBSeB4hfzRJPn-Ulg3vrBapoWqfoV7eMfgkZKtAy-hC-_ckx-JuJz36GAqR0CgDb2vXampJ4hYRFOWMkbMRfP7nYwpcUtNtIWSSCXjWaiDsNVtKcb1XhDNJwA5g-vp9HH6OLaD5BN6gVuOe59bKqujqDzdBpxJokUcqS1keVrU", "q": "yb77bqbIsIJRZJo19iJ2cbOvonEkMqcuNx6jFGyABaODn_yu21e7j7yaHEvqYV9aaAFWHqOnCwZA9NcaYxRt52KT3ZDEE9S-xim6rign4aRKookEXgR8ZzN7V2zgYeBbnTcFdPA4PnrVL8eOZ9umrsnq6ttS7dqbsu3dmyxykic", "dp": "dTvbgQ63_jMgtlj80xifLuQAeiK-oNJ7zaDY2XGgldo7plWHSlRHSCIQMBqeOn_xeSGlrmtbxyQM8L111-wn9L1Pacxiu7GjkK2CsWWam0JNQlYWVRNBvzYg6K8QfKFgEUU9hD2b74n97-sSFhEu-LFhpVLkzn7k1k0UkGDbQdk", "dq": "whDGyGADeVdCeGWnNsdb7HAOqVHwohETcc40zXa5h7MM8J8ejLxOHiwsir-0DEqvKpDuiLaf_wja_yrTpS-HsSawWlfhZbomcXS-sLzL8FAbw1HOM6pZCOUK5sRC66PoPMkqpJxXXjLGVBnAMMOoCUcOhTDJCyhY0bviilwtMc0", "qi": "DsF0dzqDMIzQGN4Zsm7fkqyrFOdLbVdok_eKPNhvLaJ_q8Abfo-ed1qzZ2v1hXYcqsM9x9fccXaYd_pEV4pxHOswlk3R1UHQqJkjNzwdxZ1xiUJSrxYPLNmJUTeNIoswRtA52zUKnhbkgKwBLJM6krBXRxa_GaUxZg44hYj7Kjo", "alg": "RS512", "kid": "OwN7kd-CjZKCgnB2H5tlaT6SR016xshTzQ1dCAl-RtI", "kty": "RSA", "use": "sig"}, {"d": "F9VroTMcmLhNwDi8hYGiVcRvfANuHafjimTpqwRKUDllXeqd17QnEUrOvyAHzXQnwhk3vgLpBqdv-wyoaq6EG0F-_OBQsW4VjQxRPoBCQgLudONgSNwmU_Nf6th9POUplc-8P-XrIiFuzkpXqMq_B-Ep5q86SaN_bqSto1TswYDxMtBYIjbOxXI2a0VKEJPg141hyCAqm2BUUgYvo15OQxGkMh4PcEJPEebWyMKTn-XGtIlcjzZQ2hzo6JpnDHLgJdmQ8I4xHqHsbLQX5NTT6QI2OXJ_m6QtiLKQ-KPXDRdN6F17sos8gEINrYEwSQNNvMOTCS8Y4dZoAKQsV-TKgw", "e": "AQAB", "n": "tHY7M3hqO-tPcYO2Lx69erif2FXVxGdB8wd_30l-JP3fiL8tAp4M6JYhvrA3DmrWOwi8M9ZjCf7sqBKtNd8p6wS5g-faT9mjfQfzMB8EyNwujFX79HpdI7wHdbZEoQbU5DFV5PFBy2ZoMKhoUg6xvn5fy0TPHup8Mjlqm-os0jpXeSqLorRypyEFTQANB0rBoImyhKEhUWe7Hph9hPfOCNa1IPv7dwzRp_7qyiAO_JAfM9ORvm8Te9Kz9OsAjt6QRTgzuAQ9fpyOSJm7Mlu3EXEaNOcOIRAtVN52rImvq0RLDwAFzkIy0AlLz26wG8F5QRJkkTA-gvbbs5mbCbUinQ", "p": "4zfAt-KP0AozPiPLGXJPUvw4Q2rwIL83xu9eOKWzsO-daKgj1vU-yIYmTTTjZkAYiA672u2l_E2ZUM6u0zHTmgZxO9uOM48fsY0SBHpceXxznLyj6SOpv8vgGuuNix7eM7i9X2n4uNb_Rd7DvyWSvbsJfQaZRbHJSjXsDLmLZzM", "q": "y1JFUQFvY_KReTZghcw0C0vVSo7rcEuXBbpL5FFb_i4QOUx8ljCf5rp6jnsvIZoDbOZ6IJgPs-TlZ2w7zZHAIVx3PGqDclTJRYiKItpX-lgxI4IH3xTcVGYTUr3exIAkwa2eM8-yQAhQV-jsMYGthRX9UP0uIsX9UaI6ua9pDu8", "dp": "4qqhpE9tq9ohGGJYn7_7Bgv6jLbHacOX_uqXkecrhNzkqJzjc_MfeKbq2qZiG4ThdAlOua3Nog4_Xe9xU9om_0Zh-5ahGyoyMctLKBBw4_iU1M0SrucW1fCqVfCaOSjH_czTjbWHm81OxwLdP3haFM_bPVAx4ubiqRd1rZQDTyU", "dq": "Jyu4cvzFywmmgSW6vswykqKPewfB0Caf99iGWnxaLsQNGBzmO8EubTMr_Vs6H00er9JPYQwqqkvE7oHpm5ci3sqDpj4XCOXQyPafNku-e1qWTPL2NUI9mHz56AzwaAcQDcg3HGA9RRzU7brQFlGXbnZoETxVsRlXzmxkx_VFVj0", "qi": "XK6D3dr-OlP9_tY8AOj4Xe4D1TZqxwCI-LDlYake0ouo9TmxLeF8LD4p34JySmTiVzXhCKTv1pkX8tDj8SKf1U_9acsUiatv5Yu7wQo_MzSYHulq620DelJAttCtWLWG285baDk5MxmQ1z-TamdG_8IClCdWgrnMQ1WUnjEb5T8", "alg": "PS256", "kid": "MjzLFr46jLbSgWA7aW62b79_NFgdKKoSLsNg7Z0i5S0", "kty": "RSA", "use": "sig"}, {"d": "A8yRVGAx5pBse-yIgo-q_0kYNhfhvvAkJfwi4No7GPQWg9Lq7MwccEI4XsniLSB118hz9Nqaw6YNKr45BurK_O-6vHh0bpja_3-XJnaFyUWOmZTCzGFL4D2Erai_I707Lw_nthr9evKxDoc0gbEIk7OmDIshYU9giwcKQS32UGdqtTNMQ5ihdDcghUomKgSmm9Ziu_Sp1MFWa-XU5FIL_dEOlp3jVUgE8kQrpd7NRkNJkDgLtg4SfXh7c5Cw0OuMMzLTZbbSZFO7HKQzm1J8DooVifmaiuou14qkO2h-1DubhQwH1DpMMTKajqPp8O5nNoyUPOdzKKzyPQQoYezGIQ", "e": "AQAB", "n": "9UpDx-P9q11vomNn9-DU1lNE08ePxXvnBwmV18hn_a5Lr_GoNXbriFUwDaKRNmuvEUvumms5D-oblSbB7s390Wo6UmAEd_1sg2pB_r2TqwukH8jmG0MUOkllJ6fC-AXgm8DCcM3vVsD5V4uM1h00EU2LUEhNsbH4umHkACaXfMTqqlmoFMq5F1mH1HO1Lia29OG2S4YRRi9dRYpaikzDUlwPP_eFw1gg7HwImhd_d5eIx-oR6rTR-ToXxHHgwqeGH0HXikZxp2NIlhzqISB8XgZMY7mAPuiTmuuRm_WHyoC20xBkS0jdrLVDHRAjPenQA4XzdtXlmxCI_SYFODaYfw", "p": "_4Kk_BdZBQs75mPlTGsiaZqp91wzmvp6FdVuBx7yDqj3vlHgsyS8lkG4UYwriKji66fYANR8i7ncKN99wfGtWxJLedjmNnqTPgi2YMGLh5-Q6wllf6CvnPJYd-DqwhErHX0yu7lqiaK4xU1MA1Gl1TkslJ89N_DxNcWbW-28owM", "q": "9cKbLZcKG0MR6mbmUHW7jpxCxU9cJc8QeP2qd2Lg_gDxWkiqrO0fYBrAA3-Ka5wrvxG7whv3ko1_U_Td4NLzfxlQXGddUnLMb4hWYYZl_IIcJuwmkjCO_Z8e_80Qvc5WYcgGIGj6taMyvcYo3Cq5vCXFknJDxwupwl1eWlFj_dU", "dp": "pvJw5HpI4v_NGqMo3n6d1IyHA6XN3jRM8tkqdCKnHCcRANy0ybh2NGMqkLXaeAeJhVp8y0YLPqypClfE7qT_lSLmB-5NtUjvzjeZGq07gtkisj_IftS6Cf1bCrD-EuFu32y_amMjFl0pB1mTEhQWG7SoyU8mi9e1c2HzOeSjPYs", "dq": "mYyMjhCHlP7zy6OdFPpqRDEnmsX5yfm0zhOXlV4nOyx1n7Y1RTQmXVJ5U_Y1EwURZCD9UctNhLh5rIgatSS4VFoJlqJScXgeeTUS234wbHMSidMUSlSikp3_rU1_v0eTOybRhSByPFiKFH4h-2WKhJ6I8fYImO2VlEXn9MBTnD0", "qi": "xdelviNzXuKX4XhUlDSFzEcZOSVTGm2jy-CR9Uq59m2nHqlIuGGhAhQhxvPGJW5OBd_R6Xa4nDfr83YOvCGV9soItIDFsJ1qYX4Hw9WL0nRZTTR4ssJRA_jQfgRJMOR4o0cIKIoJnv8NjcV8KDiKc7VkIY3WPTqKHWRYQ-TXvdw", "alg": "PS384", "kid": "2bNM0mXF3WY5x8MsV2PVa0PZLf5trXun1wR3Y7z7_RA", "kty": "RSA", "use": "sig"}, {"d": "E6Ltz_x084eDBMXpNA9n-s1Y3VxKicCNGru-_hiYRG6wtGswRExdwyYCOY6RLkvfM7nubuC9LsGqoOalt-N70Tb6NH6aOSgow303ke9iAHpM7BhpM75VKpUWLZtBFyYPAOBQsnwPJY61BXpxMD7TO9CewhaNAo_UadDZHBsu1QYNxl0Dy4DzzUdcqu5ReiZv3sRWXTUAdBxO7TrY1vGZ1GNw40ZPgoR2XbL9NmfJ1r2eCQ55eBOzrM9Ql8krn6d3RvaKo6RkKDTIcJOezXq_1hFQYgCIPNqRU4pW43LURohrIMxfZtMy879thGwNpHWsU_fefWd1kGC1iCH_2ftWSw", "e": "AQAB", "n": "r7dAmTngXaW1bdF_iqr2lkq7giJ_FX6GJDsWLEvLNUxQ5l5vi3YAk8dx-hLjthi955tEXrKJkw24rY7f1OKQX9N4nWqGdgfujp_0Cg22KOs40g1u0Qu8Vka3Sj2gKFS2HyTSOGJxIkeAfjCZJcHMRztd4hEJsS8Wp9A88nog4EIT2VGuZahQqnJCFcnx8QatwxVolEPgPMxaQrj7xZIveNC6yGFI5v30qVYhjMMXBSHKt141Ic5e3voTaDblsZNGYGmF6u5hwOFx4cAtBDkVqofOSD_RBzZa4_oyChLZhDPQBS0O3p20ydKY1R14f4Myugbmn08tXPocYGW3T4B52Q", "p": "6AlAPOG3AZ5xdwRSL6rkY4B_qerWXpRrS2E5omO8RtRiahqA-6IaZNudQ9SeRpXlXz980MR_27VLdwxA-M-vk03K3pzUhLB0DOPw95rSuIvwAUA6aMnIqN-pdmF6fIu1I4nmZ89el8SDAkaW6AbSE9b2ufUnCd8CsLJ-g7w8-nM", "q": "wdz2RcN2qqAF9-YMlJD_YDLQMg_oMlAuGuFpgwsfJuP952UZnfefjOiMgZnKrn-mDE-B_q4vZOdQ02WuL0RRXYw1g1YguLtE16KSEOX8sQQyecnAvJy1kp_B6vQTzXJwIggGi4smg2XsU26fGZ1OpOWnkbPP0ltklJlTWFMZK4M", "dp": "LsU-l4b_tmnTgSPz1PvjUVMjaIKXdzT_c5BDZ8ImvzgsJir1eMMyAsZpqrR-useYFlzbsdEJ3KVscrCboAts3oo9rCV8iMpwefCwL5ibhOtgE0B5BYo20iNTKzN21wfqGSHAuYgJDxpjNeA4pshJLAqWbOFHXyv-hNNVwQP-XpU", "dq": "td_C-_hA4Bp4_vVIYCkYLPv-7riVsn4egwFup45Lj4Tds7TZr6Wcfem9x-isicEf2vTMlE5-EEAjR_Bg1d9WJllf6vNmh2jJUTQnrMrXooq5gCCTPWAXyJMwrmiGG3x9TrAQ0-GcJDH-4NcrVDCMk48RAlSbaFJtriuaUYbEWlk", "qi": "QXGBMT6uKISy9EzvoYNNIhk2iOEZBODjKN63RbBV89dftDaTtHlrLZkbpQZ1h327QZvrWAiH2pm2S7xXm0bHXiiYUQjsn2nqX5c6eLsRk2onwnaUCXRmX8wqXHGZ0WeqDuVomE47JoZiEWKynsnQjAc9A8nTsgId5UcdStavQV8", "alg": "PS512", "kid": "GbOso9vlGuyg7t53VtIx9XFndDdeKaBvPtAvqwRWC1E", "kty": "RSA", "use": "sig"}, {"d": "_oJBwlbaVGrZ36xUm4V-pGFdt_XG4Ee1vNbSwruW1Ag", "x": "NHai0f5yv-sTOVjgLWRliCKNmiUv19BtmcoaNkPUR_M", "y": "DCNNoa0abLAJIoxsmFHuHolHa7IR-IJjaAODyVcgTls", "alg": "ES256", "crv": "P-256", "kid": "HKfzYocpZ5XY-j13mxpcl37uXoVPmDAtCOlYPjxew3M", "kty": "EC", "use": "sig"}, {"d": "y9a-d0mWIpaVbigfMabo7WQqTYxZD5oQPHa2W5xU1s8xPpOntqldrisfxGqI_E4H", "x": "QbfYJiwDR0Rgx7NNrBQKP9oDbraBL4B8XD1_7ICQhEhzlCpElufEJ0SVugNisCAP", "y": "9KXYnhYbtJYE2J5ajWpPpMa95tw2VqpFt8XYfcChu1dLo1jmF7RJitkg0ctWmE5U", "alg": "ES384", "crv": "P-384", "kid": "8t17_ikCreZ0yi9Wjyop7KovstCJsmAkXtUjFL1Qfdw", "kty": "EC", "use": "sig"}, {"d": "1rLOehXFegbi5oi-zWNHMGh_YGHY7JZ1y0Naq4dQcwEytoD5ZvN4BnqYkBQDRTVuF1osBQg-f31BvAhvEtXwTAY", "x": "-_kzuUz0ESyn_l-0soj3DknzYDA3va5-5lyNyJbBgq_4szdp0trrQWyEkfNNAP9k2M2DqoteTU6ZoYJx3qwoHf4", "y": "AejnT9KMzS_PdsCkXfjTSkN_LMmUt1WXhI5BRHXkkePkNbvMFVoMqdfafpvhNXEYExg118deyo0FUJ50Ky4QvMof", "alg": "ES512", "crv": "P-521", "kid": "kh7F8JeSP3zZMV0cHmYpGM5927NJ4J_feXCnkcWDfGs", "kty": "EC", "use": "sig"}, {"d": "oB7Rq4fH5A8ClhZwtnzQNnMIv_yncPtDIkHmTA7sl4U", "x": "kWvMlBQ3NTCIQeaOWWUFfD1SuVTYX7P0SSkWagd1qms", "alg": "EdDSA", "crv": "Ed25519", "kid": "0U7iRG_Qth9b_YsZt0S3owjheBLrsJaoH0NCbmNR7L8", "kty": "OKP", "use": "sig"}, {"d": "b4bybLOq3LWZwFQKALwKHb9jS4Yb_gLm79UZlSRRyvVtJ-9Pz_rb7TJEqeO_VRTNg6X6FK5yuA2B", "x": "1H6ymMVFbFIvILvVXqvJuMAiw7mJIZzEgjpWpkJlRsdlMw7m3MbMl5zLrbQHQOu673VWqNxoi6wA", "alg": "EdDSA", "crv": "Ed448", "kid": "MKv7eKXuM5r9WZmjyJ0addR2CDy9j4f_NOw-qF0HfCE", "kty": "OKP", "use": "sig"}]}
\.


--
-- Data for Name: parameters; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.parameters (key, value, created_at, updated_at) FROM stdin;
cluster_id	4f849729-8614-40c2-8c24-96e37ab13d52	\N	2024-09-14 07:25:58+00
\.


--
-- Data for Name: plugins; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.plugins (id, created_at, name, consumer_id, service_id, route_id, config, enabled, cache_key, protocols, tags, ws_id, instance_name, updated_at, ordering, consumer_group_id) FROM stdin;
\.


--
-- Data for Name: ratelimiting_metrics; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.ratelimiting_metrics (identifier, period, period_date, service_id, route_id, value, ttl) FROM stdin;
\.


--
-- Data for Name: rbac_role_endpoints; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.rbac_role_endpoints (role_id, workspace, endpoint, actions, comment, created_at, negative, updated_at) FROM stdin;
526b3889-5e85-4098-bd64-274ece0f3d8e	*	*	1	\N	2024-09-14 07:25:57+00	f	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	*	15	\N	2024-09-14 07:25:57+00	f	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/rbac/*	15	\N	2024-09-14 07:25:57+00	t	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/rbac/*/*	15	\N	2024-09-14 07:25:57+00	t	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/rbac/*/*/*	15	\N	2024-09-14 07:25:57+00	t	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/rbac/*/*/*/*	15	\N	2024-09-14 07:25:57+00	t	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/rbac/*/*/*/*/*	15	\N	2024-09-14 07:25:57+00	t	2024-09-14 07:25:58+00
605ff571-42ce-4d4a-82c8-809a5fb189d7	*	*	15	\N	2024-09-14 07:25:57+00	f	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/admins	15	\N	2024-09-14 07:25:58+00	t	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/admins/*	15	\N	2024-09-14 07:25:58+00	t	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/groups	15	\N	2024-09-14 07:25:58+00	t	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	*	/groups/*	15	\N	2024-09-14 07:25:58+00	t	2024-09-14 07:25:58+00
\.


--
-- Data for Name: rbac_role_entities; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.rbac_role_entities (role_id, entity_id, entity_type, actions, negative, comment, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rbac_roles; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.rbac_roles (id, name, comment, created_at, is_default, ws_id, updated_at) FROM stdin;
526b3889-5e85-4098-bd64-274ece0f3d8e	read-only	Read access to all endpoints, across all workspaces	2024-09-14 07:25:57+00	f	5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	2024-09-14 07:25:58+00
5c5103e5-fc89-461d-9081-79c0068261fd	admin	Full access to all endpoints, across all workspacesΓÇöexcept RBAC Admin API	2024-09-14 07:25:57+00	f	5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	2024-09-14 07:25:58+00
605ff571-42ce-4d4a-82c8-809a5fb189d7	super-admin	Full access to all endpoints, across all workspaces	2024-09-14 07:25:57+00	f	5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	2024-09-14 07:25:58+00
\.


--
-- Data for Name: rbac_user_groups; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.rbac_user_groups (user_id, group_id) FROM stdin;
\.


--
-- Data for Name: rbac_user_roles; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.rbac_user_roles (user_id, role_id, role_source) FROM stdin;
\.


--
-- Data for Name: rbac_users; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.rbac_users (id, name, user_token, user_token_ident, comment, enabled, created_at, ws_id, updated_at) FROM stdin;
\.


--
-- Data for Name: response_ratelimiting_metrics; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.response_ratelimiting_metrics (identifier, period, period_date, service_id, route_id, value) FROM stdin;
\.


--
-- Data for Name: rl_counters; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.rl_counters (key, namespace, window_start, window_size, count) FROM stdin;
\.


--
-- Data for Name: routes; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.routes (id, created_at, updated_at, name, service_id, protocols, methods, hosts, paths, snis, sources, destinations, regex_priority, strip_path, preserve_host, tags, https_redirect_status_code, headers, path_handling, ws_id, request_buffering, response_buffering, expression, priority) FROM stdin;
\.


--
-- Data for Name: schema_meta; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.schema_meta (key, subsystem, last_executed, executed, pending) FROM stdin;
schema_meta	enterprise	021_3700_to_3800_1	{000_base,006_1301_to_1500,006_1301_to_1302,010_1500_to_2100,007_1500_to_1504,008_1504_to_1505,007_1500_to_2100,009_1506_to_1507,009_2100_to_2200,010_2200_to_2211,010_2200_to_2300,010_2200_to_2300_1,011_2300_to_2600,012_2600_to_2700,012_2600_to_2700_1,013_2700_to_2800,014_2800_to_3000,015_3000_to_3100,016_3100_to_3200,017_3200_to_3300,018_3300_to_3400,019_3500_to_3600,020_3600_to_3700,021_3700_to_3800,021_3700_to_3800_1}	{}
schema_meta	core	023_360_to_370	{000_base,003_100_to_110,004_110_to_120,005_120_to_130,006_130_to_140,007_140_to_150,008_150_to_200,009_200_to_210,010_210_to_211,011_212_to_213,012_213_to_220,013_220_to_230,014_230_to_260,015_260_to_270,016_270_to_280,016_280_to_300,017_300_to_310,018_310_to_320,019_320_to_330,020_330_to_340,021_340_to_350,022_350_to_360,023_360_to_370}	{}
schema_meta	hmac-auth	003_200_to_210	{000_base_hmac_auth,002_130_to_140,003_200_to_210}	{}
schema_meta	http-log	001_280_to_300	{001_280_to_300}	{}
schema_meta	acl	004_212_to_213	{000_base_acl,002_130_to_140,003_200_to_210,004_212_to_213}	{}
schema_meta	ip-restriction	001_200_to_210	{001_200_to_210}	{}
schema_meta	rate-limiting	006_350_to_360	{000_base_rate_limiting,003_10_to_112,004_200_to_210,005_320_to_330,006_350_to_360}	{}
schema_meta	acme	003_350_to_360	{000_base_acme,001_280_to_300,002_320_to_330,003_350_to_360}	{}
schema_meta	ai-proxy	001_360_to_370	{001_360_to_370}	{}
schema_meta	oauth2	007_320_to_330	{000_base_oauth2,003_130_to_140,004_200_to_210,005_210_to_211,006_320_to_330,007_320_to_330}	{}
schema_meta	jwt	003_200_to_210	{000_base_jwt,002_130_to_140,003_200_to_210}	{}
schema_meta	ai-rate-limiting-advanced	002_370_to_380	{001_370_to_380,002_370_to_380}	{}
schema_meta	jwt-signer	001_200_to_210	{000_base_jwt_signer,001_200_to_210}	\N
schema_meta	basic-auth	003_200_to_210	{000_base_basic_auth,002_130_to_140,003_200_to_210}	{}
schema_meta	bot-detection	001_200_to_210	{001_200_to_210}	{}
schema_meta	canary	001_200_to_210	{001_200_to_210}	{}
schema_meta	degraphql	000_base	{000_base}	\N
schema_meta	graphql-proxy-cache-advanced	002_370_to_380	{001_370_to_380,002_370_to_380}	{}
schema_meta	enterprise.acl	001_1500_to_2100	{001_1500_to_2100}	{}
schema_meta	key-auth	004_320_to_330	{000_base_key_auth,002_130_to_140,003_200_to_210,004_320_to_330}	{}
schema_meta	graphql-rate-limiting-advanced	002_370_to_380	{000_base_gql_rate_limiting,001_370_to_380,002_370_to_380}	{}
schema_meta	header-cert-auth	000_base_header_cert_auth	{000_base_header_cert_auth}	\N
schema_meta	response-ratelimiting	001_350_to_360	{000_base_response_rate_limiting,001_350_to_360}	{}
schema_meta	key-auth-enc	001_200_to_210	{000_base_key_auth_enc,001_200_to_210}	{}
schema_meta	saml	001_370_to_380	{001_370_to_380}	{}
schema_meta	konnect-application-auth	004_exhausted_scopes_addition	{000_base_konnect_applications,001_consumer_group_addition,002_strategy_id_addition,003_application_context,004_exhausted_scopes_addition}	\N
schema_meta	openid-connect	004_370_to_380	{000_base_openid_connect,001_14_to_15,002_200_to_210,003_280_to_300,004_370_to_380}	{}
schema_meta	mtls-auth	002_2200_to_2300	{000_base_mtls_auth,001_200_to_210,002_2200_to_2300}	{}
schema_meta	opentelemetry	001_331_to_332	{001_331_to_332}	{}
schema_meta	enterprise.hmac-auth	001_1500_to_2100	{001_1500_to_2100}	{}
schema_meta	post-function	001_280_to_300	{001_280_to_300}	{}
schema_meta	pre-function	001_280_to_300	{001_280_to_300}	{}
schema_meta	session	002_320_to_330	{000_base_session,001_add_ttl_index,002_320_to_330}	\N
schema_meta	enterprise.basic-auth	001_1500_to_2100	{001_1500_to_2100}	{}
schema_meta	vault-auth	002_300_to_310	{000_base_vault_auth,001_280_to_300,002_300_to_310}	\N
schema_meta	enterprise.jwt	001_1500_to_2100	{001_1500_to_2100}	{}
schema_meta	enterprise.key-auth	001_1500_to_2100	{001_1500_to_2100}	{}
schema_meta	enterprise.oauth2	002_2200_to_2211	{001_1500_to_2100,002_2200_to_2211}	{}
schema_meta	enterprise.mtls-auth	002_2200_to_2300	{001_1500_to_2100,002_2200_to_2300}	{}
schema_meta	enterprise.key-auth-enc	002_2800_to_3200	{001_1500_to_2100,002_3100_to_3200,002_2800_to_3200}	{}
schema_meta	enterprise.request-transformer-advanced	001_1500_to_2100	{001_1500_to_2100}	{}
schema_meta	enterprise.response-transformer-advanced	001_1500_to_2100	{001_1500_to_2100}	{}
\.


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.services (id, created_at, updated_at, name, retries, protocol, host, port, path, connect_timeout, write_timeout, read_timeout, tags, client_certificate_id, tls_verify, tls_verify_depth, ca_certificates, ws_id, enabled) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.sessions (id, session_id, expires, data, created_at, ttl) FROM stdin;
\.


--
-- Data for Name: sm_vaults; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.sm_vaults (id, ws_id, prefix, name, description, config, created_at, updated_at, tags) FROM stdin;
\.


--
-- Data for Name: snis; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.snis (id, created_at, name, certificate_id, tags, ws_id, updated_at) FROM stdin;
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.tags (entity_id, entity_name, tags) FROM stdin;
\.


--
-- Data for Name: targets; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.targets (id, created_at, upstream_id, target, weight, tags, ws_id, cache_key, updated_at) FROM stdin;
\.


--
-- Data for Name: upstreams; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.upstreams (id, created_at, name, hash_on, hash_fallback, hash_on_header, hash_fallback_header, hash_on_cookie, hash_on_cookie_path, slots, healthchecks, tags, algorithm, host_header, client_certificate_id, ws_id, hash_on_query_arg, hash_fallback_query_arg, hash_on_uri_capture, hash_fallback_uri_capture, use_srv_name, updated_at) FROM stdin;
\.


--
-- Data for Name: vault_auth_vaults; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vault_auth_vaults (id, created_at, updated_at, name, protocol, host, port, mount, vault_token, kv) FROM stdin;
\.


--
-- Data for Name: vaults; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vaults (id, created_at, updated_at, name, protocol, host, port, mount, vault_token) FROM stdin;
\.


--
-- Data for Name: vitals_code_classes_by_cluster; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_code_classes_by_cluster (code_class, at, duration, count) FROM stdin;
\.


--
-- Data for Name: vitals_code_classes_by_workspace; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_code_classes_by_workspace (workspace_id, code_class, at, duration, count) FROM stdin;
\.


--
-- Data for Name: vitals_codes_by_consumer_route; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_codes_by_consumer_route (consumer_id, service_id, route_id, code, at, duration, count) FROM stdin;
\.


--
-- Data for Name: vitals_codes_by_route; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_codes_by_route (service_id, route_id, code, at, duration, count) FROM stdin;
\.


--
-- Data for Name: vitals_locks; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_locks (key, expiry) FROM stdin;
delete_status_codes	\N
\.


--
-- Data for Name: vitals_node_meta; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_node_meta (node_id, first_report, last_report, hostname) FROM stdin;
\.


--
-- Data for Name: vitals_stats_days; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_stats_days (node_id, at, l2_hit, l2_miss, plat_min, plat_max, ulat_min, ulat_max, requests, plat_count, plat_total, ulat_count, ulat_total) FROM stdin;
\.


--
-- Data for Name: vitals_stats_hours; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_stats_hours (at, l2_hit, l2_miss, plat_min, plat_max) FROM stdin;
\.


--
-- Data for Name: vitals_stats_minutes; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_stats_minutes (node_id, at, l2_hit, l2_miss, plat_min, plat_max, ulat_min, ulat_max, requests, plat_count, plat_total, ulat_count, ulat_total) FROM stdin;
\.


--
-- Data for Name: vitals_stats_seconds; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.vitals_stats_seconds (node_id, at, l2_hit, l2_miss, plat_min, plat_max, ulat_min, ulat_max, requests, plat_count, plat_total, ulat_count, ulat_total) FROM stdin;
\.


--
-- Data for Name: workspace_entities; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.workspace_entities (workspace_id, workspace_name, entity_id, entity_type, unique_field_name, unique_field_value) FROM stdin;
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	default	526b3889-5e85-4098-bd64-274ece0f3d8e	rbac_roles	id	526b3889-5e85-4098-bd64-274ece0f3d8e
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	default	526b3889-5e85-4098-bd64-274ece0f3d8e	rbac_roles	name	default:read-only
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	default	5c5103e5-fc89-461d-9081-79c0068261fd	rbac_roles	id	5c5103e5-fc89-461d-9081-79c0068261fd
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	default	5c5103e5-fc89-461d-9081-79c0068261fd	rbac_roles	name	default:admin
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	default	605ff571-42ce-4d4a-82c8-809a5fb189d7	rbac_roles	id	605ff571-42ce-4d4a-82c8-809a5fb189d7
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	default	605ff571-42ce-4d4a-82c8-809a5fb189d7	rbac_roles	name	default:super-admin
\.


--
-- Data for Name: workspace_entity_counters; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.workspace_entity_counters (workspace_id, entity_type, count) FROM stdin;
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	rbac_roles	3
\.


--
-- Data for Name: workspaces; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.workspaces (id, name, comment, created_at, meta, config, updated_at) FROM stdin;
5c5ae7cb-8e9c-4a34-92a6-92b0a243ee6c	default	\N	2024-09-14 07:25:56+00	\N	\N	2024-09-14 07:25:56+00
\.


--
-- Data for Name: ws_migrations_backup; Type: TABLE DATA; Schema: public; Owner: kong
--

COPY public.ws_migrations_backup (entity_type, entity_id, unique_field_name, unique_field_value, created_at) FROM stdin;
\.


--
-- Name: clustering_rpc_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kong
--

SELECT pg_catalog.setval('public.clustering_rpc_requests_id_seq', 1, false);


--
-- Name: acls acls_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.acls
    ADD CONSTRAINT acls_cache_key_key UNIQUE (cache_key);


--
-- Name: acls acls_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.acls
    ADD CONSTRAINT acls_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: acls acls_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.acls
    ADD CONSTRAINT acls_pkey PRIMARY KEY (id);


--
-- Name: acme_storage acme_storage_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.acme_storage
    ADD CONSTRAINT acme_storage_key_key UNIQUE (key);


--
-- Name: acme_storage acme_storage_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.acme_storage
    ADD CONSTRAINT acme_storage_pkey PRIMARY KEY (id);


--
-- Name: admins admins_custom_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_custom_id_key UNIQUE (custom_id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: admins admins_username_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_username_key UNIQUE (username);


--
-- Name: application_instances application_instances_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.application_instances
    ADD CONSTRAINT application_instances_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: application_instances application_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.application_instances
    ADD CONSTRAINT application_instances_pkey PRIMARY KEY (id);


--
-- Name: application_instances application_instances_ws_id_composite_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.application_instances
    ADD CONSTRAINT application_instances_ws_id_composite_id_unique UNIQUE (ws_id, composite_id);


--
-- Name: applications applications_custom_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_custom_id_key UNIQUE (custom_id);


--
-- Name: applications applications_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: audit_objects audit_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.audit_objects
    ADD CONSTRAINT audit_objects_pkey PRIMARY KEY (id);


--
-- Name: audit_requests audit_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.audit_requests
    ADD CONSTRAINT audit_requests_pkey PRIMARY KEY (request_id);


--
-- Name: basicauth_credentials basicauth_credentials_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.basicauth_credentials
    ADD CONSTRAINT basicauth_credentials_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: basicauth_credentials basicauth_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.basicauth_credentials
    ADD CONSTRAINT basicauth_credentials_pkey PRIMARY KEY (id);


--
-- Name: basicauth_credentials basicauth_credentials_ws_id_username_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.basicauth_credentials
    ADD CONSTRAINT basicauth_credentials_ws_id_username_unique UNIQUE (ws_id, username);


--
-- Name: ca_certificates ca_certificates_cert_digest_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.ca_certificates
    ADD CONSTRAINT ca_certificates_cert_digest_key UNIQUE (cert_digest);


--
-- Name: ca_certificates ca_certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.ca_certificates
    ADD CONSTRAINT ca_certificates_pkey PRIMARY KEY (id);


--
-- Name: certificates certificates_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: certificates certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_pkey PRIMARY KEY (id);


--
-- Name: cluster_events cluster_events_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.cluster_events
    ADD CONSTRAINT cluster_events_pkey PRIMARY KEY (id);


--
-- Name: clustering_data_planes clustering_data_planes_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.clustering_data_planes
    ADD CONSTRAINT clustering_data_planes_pkey PRIMARY KEY (id);


--
-- Name: clustering_rpc_requests clustering_rpc_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.clustering_rpc_requests
    ADD CONSTRAINT clustering_rpc_requests_pkey PRIMARY KEY (id);


--
-- Name: consumer_group_consumers consumer_group_consumers_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_consumers
    ADD CONSTRAINT consumer_group_consumers_cache_key_key UNIQUE (cache_key);


--
-- Name: consumer_group_consumers consumer_group_consumers_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_consumers
    ADD CONSTRAINT consumer_group_consumers_pkey PRIMARY KEY (consumer_group_id, consumer_id);


--
-- Name: consumer_group_plugins consumer_group_plugins_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_plugins
    ADD CONSTRAINT consumer_group_plugins_cache_key_key UNIQUE (cache_key);


--
-- Name: consumer_group_plugins consumer_group_plugins_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_plugins
    ADD CONSTRAINT consumer_group_plugins_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: consumer_group_plugins consumer_group_plugins_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_plugins
    ADD CONSTRAINT consumer_group_plugins_pkey PRIMARY KEY (id);


--
-- Name: consumer_groups consumer_groups_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_groups
    ADD CONSTRAINT consumer_groups_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: consumer_groups consumer_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_groups
    ADD CONSTRAINT consumer_groups_pkey PRIMARY KEY (id);


--
-- Name: consumer_groups consumer_groups_ws_id_name_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_groups
    ADD CONSTRAINT consumer_groups_ws_id_name_unique UNIQUE (ws_id, name);


--
-- Name: consumer_reset_secrets consumer_reset_secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_reset_secrets
    ADD CONSTRAINT consumer_reset_secrets_pkey PRIMARY KEY (id);


--
-- Name: consumers consumers_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT consumers_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: consumers consumers_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT consumers_pkey PRIMARY KEY (id);


--
-- Name: consumers consumers_ws_id_custom_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT consumers_ws_id_custom_id_unique UNIQUE (ws_id, custom_id);


--
-- Name: consumers consumers_ws_id_username_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT consumers_ws_id_username_unique UNIQUE (ws_id, username);


--
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (id);


--
-- Name: degraphql_routes degraphql_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.degraphql_routes
    ADD CONSTRAINT degraphql_routes_pkey PRIMARY KEY (id);


--
-- Name: developers developers_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: developers developers_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_pkey PRIMARY KEY (id);


--
-- Name: developers developers_ws_id_custom_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_ws_id_custom_id_unique UNIQUE (ws_id, custom_id);


--
-- Name: developers developers_ws_id_email_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_ws_id_email_unique UNIQUE (ws_id, email);


--
-- Name: document_objects document_objects_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.document_objects
    ADD CONSTRAINT document_objects_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: document_objects document_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.document_objects
    ADD CONSTRAINT document_objects_pkey PRIMARY KEY (id);


--
-- Name: document_objects document_objects_ws_id_path_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.document_objects
    ADD CONSTRAINT document_objects_ws_id_path_unique UNIQUE (ws_id, path);


--
-- Name: event_hooks event_hooks_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.event_hooks
    ADD CONSTRAINT event_hooks_id_key UNIQUE (id);


--
-- Name: files files_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: files files_ws_id_path_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_ws_id_path_unique UNIQUE (ws_id, path);


--
-- Name: filter_chains filter_chains_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.filter_chains
    ADD CONSTRAINT filter_chains_cache_key_key UNIQUE (cache_key);


--
-- Name: filter_chains filter_chains_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.filter_chains
    ADD CONSTRAINT filter_chains_name_key UNIQUE (name);


--
-- Name: filter_chains filter_chains_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.filter_chains
    ADD CONSTRAINT filter_chains_pkey PRIMARY KEY (id);


--
-- Name: graphql_ratelimiting_advanced_cost_decoration graphql_ratelimiting_advanced_cost_decoration_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.graphql_ratelimiting_advanced_cost_decoration
    ADD CONSTRAINT graphql_ratelimiting_advanced_cost_decoration_pkey PRIMARY KEY (id);


--
-- Name: group_rbac_roles group_rbac_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.group_rbac_roles
    ADD CONSTRAINT group_rbac_roles_pkey PRIMARY KEY (group_id, rbac_role_id);


--
-- Name: groups groups_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: header_cert_auth_credentials header_cert_auth_credentials_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.header_cert_auth_credentials
    ADD CONSTRAINT header_cert_auth_credentials_cache_key_key UNIQUE (cache_key);


--
-- Name: header_cert_auth_credentials header_cert_auth_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.header_cert_auth_credentials
    ADD CONSTRAINT header_cert_auth_credentials_pkey PRIMARY KEY (id);


--
-- Name: hmacauth_credentials hmacauth_credentials_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.hmacauth_credentials
    ADD CONSTRAINT hmacauth_credentials_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: hmacauth_credentials hmacauth_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.hmacauth_credentials
    ADD CONSTRAINT hmacauth_credentials_pkey PRIMARY KEY (id);


--
-- Name: hmacauth_credentials hmacauth_credentials_ws_id_username_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.hmacauth_credentials
    ADD CONSTRAINT hmacauth_credentials_ws_id_username_unique UNIQUE (ws_id, username);


--
-- Name: jwt_secrets jwt_secrets_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.jwt_secrets
    ADD CONSTRAINT jwt_secrets_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: jwt_secrets jwt_secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.jwt_secrets
    ADD CONSTRAINT jwt_secrets_pkey PRIMARY KEY (id);


--
-- Name: jwt_secrets jwt_secrets_ws_id_key_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.jwt_secrets
    ADD CONSTRAINT jwt_secrets_ws_id_key_unique UNIQUE (ws_id, key);


--
-- Name: jwt_signer_jwks jwt_signer_jwks_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.jwt_signer_jwks
    ADD CONSTRAINT jwt_signer_jwks_name_key UNIQUE (name);


--
-- Name: jwt_signer_jwks jwt_signer_jwks_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.jwt_signer_jwks
    ADD CONSTRAINT jwt_signer_jwks_pkey PRIMARY KEY (id);


--
-- Name: key_sets key_sets_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.key_sets
    ADD CONSTRAINT key_sets_name_key UNIQUE (name);


--
-- Name: key_sets key_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.key_sets
    ADD CONSTRAINT key_sets_pkey PRIMARY KEY (id);


--
-- Name: keyauth_credentials keyauth_credentials_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_credentials
    ADD CONSTRAINT keyauth_credentials_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: keyauth_credentials keyauth_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_credentials
    ADD CONSTRAINT keyauth_credentials_pkey PRIMARY KEY (id);


--
-- Name: keyauth_credentials keyauth_credentials_ws_id_key_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_credentials
    ADD CONSTRAINT keyauth_credentials_ws_id_key_unique UNIQUE (ws_id, key);


--
-- Name: keyauth_enc_credentials keyauth_enc_credentials_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_enc_credentials
    ADD CONSTRAINT keyauth_enc_credentials_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: keyauth_enc_credentials keyauth_enc_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_enc_credentials
    ADD CONSTRAINT keyauth_enc_credentials_pkey PRIMARY KEY (id);


--
-- Name: keyauth_enc_credentials keyauth_enc_credentials_ws_id_key_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_enc_credentials
    ADD CONSTRAINT keyauth_enc_credentials_ws_id_key_unique UNIQUE (ws_id, key);


--
-- Name: keyring_keys keyring_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyring_keys
    ADD CONSTRAINT keyring_keys_pkey PRIMARY KEY (id);


--
-- Name: keyring_meta keyring_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyring_meta
    ADD CONSTRAINT keyring_meta_pkey PRIMARY KEY (id);


--
-- Name: keys keys_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_cache_key_key UNIQUE (cache_key);


--
-- Name: keys keys_kid_set_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_kid_set_id_key UNIQUE (kid, set_id);


--
-- Name: keys keys_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_name_key UNIQUE (name);


--
-- Name: keys keys_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_pkey PRIMARY KEY (id);


--
-- Name: konnect_applications konnect_applications_client_id_ws_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.konnect_applications
    ADD CONSTRAINT konnect_applications_client_id_ws_id_key UNIQUE (client_id, ws_id);


--
-- Name: konnect_applications konnect_applications_id_ws_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.konnect_applications
    ADD CONSTRAINT konnect_applications_id_ws_id_key UNIQUE (id, ws_id);


--
-- Name: konnect_applications konnect_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.konnect_applications
    ADD CONSTRAINT konnect_applications_pkey PRIMARY KEY (id);


--
-- Name: legacy_files legacy_files_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.legacy_files
    ADD CONSTRAINT legacy_files_name_key UNIQUE (name);


--
-- Name: legacy_files legacy_files_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.legacy_files
    ADD CONSTRAINT legacy_files_pkey PRIMARY KEY (id);


--
-- Name: licenses licenses_checksum_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.licenses
    ADD CONSTRAINT licenses_checksum_key UNIQUE (checksum);


--
-- Name: licenses licenses_payload_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.licenses
    ADD CONSTRAINT licenses_payload_key UNIQUE (payload);


--
-- Name: licenses licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.licenses
    ADD CONSTRAINT licenses_pkey PRIMARY KEY (id);


--
-- Name: locks locks_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.locks
    ADD CONSTRAINT locks_pkey PRIMARY KEY (key);


--
-- Name: login_attempts login_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.login_attempts
    ADD CONSTRAINT login_attempts_pkey PRIMARY KEY (consumer_id, attempt_type);


--
-- Name: mtls_auth_credentials mtls_auth_credentials_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.mtls_auth_credentials
    ADD CONSTRAINT mtls_auth_credentials_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: mtls_auth_credentials mtls_auth_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.mtls_auth_credentials
    ADD CONSTRAINT mtls_auth_credentials_pkey PRIMARY KEY (id);


--
-- Name: mtls_auth_credentials mtls_auth_credentials_ws_id_cache_key_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.mtls_auth_credentials
    ADD CONSTRAINT mtls_auth_credentials_ws_id_cache_key_unique UNIQUE (ws_id, cache_key);


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_authorization_codes
    ADD CONSTRAINT oauth2_authorization_codes_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_authorization_codes
    ADD CONSTRAINT oauth2_authorization_codes_pkey PRIMARY KEY (id);


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_ws_id_code_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_authorization_codes
    ADD CONSTRAINT oauth2_authorization_codes_ws_id_code_unique UNIQUE (ws_id, code);


--
-- Name: oauth2_credentials oauth2_credentials_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_credentials
    ADD CONSTRAINT oauth2_credentials_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: oauth2_credentials oauth2_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_credentials
    ADD CONSTRAINT oauth2_credentials_pkey PRIMARY KEY (id);


--
-- Name: oauth2_credentials oauth2_credentials_ws_id_client_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_credentials
    ADD CONSTRAINT oauth2_credentials_ws_id_client_id_unique UNIQUE (ws_id, client_id);


--
-- Name: oauth2_tokens oauth2_tokens_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_tokens
    ADD CONSTRAINT oauth2_tokens_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: oauth2_tokens oauth2_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_tokens
    ADD CONSTRAINT oauth2_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth2_tokens oauth2_tokens_ws_id_access_token_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_tokens
    ADD CONSTRAINT oauth2_tokens_ws_id_access_token_unique UNIQUE (ws_id, access_token);


--
-- Name: oauth2_tokens oauth2_tokens_ws_id_refresh_token_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_tokens
    ADD CONSTRAINT oauth2_tokens_ws_id_refresh_token_unique UNIQUE (ws_id, refresh_token);


--
-- Name: oic_issuers oic_issuers_issuer_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oic_issuers
    ADD CONSTRAINT oic_issuers_issuer_key UNIQUE (issuer);


--
-- Name: oic_issuers oic_issuers_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oic_issuers
    ADD CONSTRAINT oic_issuers_pkey PRIMARY KEY (id);


--
-- Name: oic_jwks oic_jwks_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oic_jwks
    ADD CONSTRAINT oic_jwks_pkey PRIMARY KEY (id);


--
-- Name: parameters parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_pkey PRIMARY KEY (key);


--
-- Name: plugins plugins_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_cache_key_key UNIQUE (cache_key);


--
-- Name: plugins plugins_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: plugins plugins_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_pkey PRIMARY KEY (id);


--
-- Name: plugins plugins_ws_id_instance_name_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_ws_id_instance_name_unique UNIQUE (ws_id, instance_name);


--
-- Name: ratelimiting_metrics ratelimiting_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.ratelimiting_metrics
    ADD CONSTRAINT ratelimiting_metrics_pkey PRIMARY KEY (identifier, period, period_date, service_id, route_id);


--
-- Name: rbac_role_endpoints rbac_role_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_role_endpoints
    ADD CONSTRAINT rbac_role_endpoints_pkey PRIMARY KEY (role_id, workspace, endpoint);


--
-- Name: rbac_role_entities rbac_role_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_role_entities
    ADD CONSTRAINT rbac_role_entities_pkey PRIMARY KEY (role_id, entity_id);


--
-- Name: rbac_roles rbac_roles_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_roles
    ADD CONSTRAINT rbac_roles_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: rbac_roles rbac_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_roles
    ADD CONSTRAINT rbac_roles_pkey PRIMARY KEY (id);


--
-- Name: rbac_roles rbac_roles_ws_id_name_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_roles
    ADD CONSTRAINT rbac_roles_ws_id_name_unique UNIQUE (ws_id, name);


--
-- Name: rbac_user_groups rbac_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_user_groups
    ADD CONSTRAINT rbac_user_groups_pkey PRIMARY KEY (user_id, group_id);


--
-- Name: rbac_user_roles rbac_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_user_roles
    ADD CONSTRAINT rbac_user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: rbac_users rbac_users_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_users
    ADD CONSTRAINT rbac_users_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: rbac_users rbac_users_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_users
    ADD CONSTRAINT rbac_users_pkey PRIMARY KEY (id);


--
-- Name: rbac_users rbac_users_user_token_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_users
    ADD CONSTRAINT rbac_users_user_token_key UNIQUE (user_token);


--
-- Name: rbac_users rbac_users_ws_id_name_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_users
    ADD CONSTRAINT rbac_users_ws_id_name_unique UNIQUE (ws_id, name);


--
-- Name: response_ratelimiting_metrics response_ratelimiting_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.response_ratelimiting_metrics
    ADD CONSTRAINT response_ratelimiting_metrics_pkey PRIMARY KEY (identifier, period, period_date, service_id, route_id);


--
-- Name: rl_counters rl_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rl_counters
    ADD CONSTRAINT rl_counters_pkey PRIMARY KEY (key, namespace, window_start, window_size);


--
-- Name: routes routes_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: routes routes_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);


--
-- Name: routes routes_ws_id_name_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_ws_id_name_unique UNIQUE (ws_id, name);


--
-- Name: schema_meta schema_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.schema_meta
    ADD CONSTRAINT schema_meta_pkey PRIMARY KEY (key, subsystem);


--
-- Name: services services_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: services services_ws_id_name_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_ws_id_name_unique UNIQUE (ws_id, name);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_session_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_session_id_key UNIQUE (session_id);


--
-- Name: sm_vaults sm_vaults_id_ws_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.sm_vaults
    ADD CONSTRAINT sm_vaults_id_ws_id_key UNIQUE (id, ws_id);


--
-- Name: sm_vaults sm_vaults_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.sm_vaults
    ADD CONSTRAINT sm_vaults_pkey PRIMARY KEY (id);


--
-- Name: sm_vaults sm_vaults_prefix_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.sm_vaults
    ADD CONSTRAINT sm_vaults_prefix_key UNIQUE (prefix);


--
-- Name: sm_vaults sm_vaults_prefix_ws_id_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.sm_vaults
    ADD CONSTRAINT sm_vaults_prefix_ws_id_key UNIQUE (prefix, ws_id);


--
-- Name: snis snis_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.snis
    ADD CONSTRAINT snis_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: snis snis_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.snis
    ADD CONSTRAINT snis_name_key UNIQUE (name);


--
-- Name: snis snis_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.snis
    ADD CONSTRAINT snis_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (entity_id);


--
-- Name: targets targets_cache_key_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_cache_key_key UNIQUE (cache_key);


--
-- Name: targets targets_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: targets targets_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_pkey PRIMARY KEY (id);


--
-- Name: upstreams upstreams_id_ws_id_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.upstreams
    ADD CONSTRAINT upstreams_id_ws_id_unique UNIQUE (id, ws_id);


--
-- Name: upstreams upstreams_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.upstreams
    ADD CONSTRAINT upstreams_pkey PRIMARY KEY (id);


--
-- Name: upstreams upstreams_ws_id_name_unique; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.upstreams
    ADD CONSTRAINT upstreams_ws_id_name_unique UNIQUE (ws_id, name);


--
-- Name: vault_auth_vaults vault_auth_vaults_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vault_auth_vaults
    ADD CONSTRAINT vault_auth_vaults_name_key UNIQUE (name);


--
-- Name: vault_auth_vaults vault_auth_vaults_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vault_auth_vaults
    ADD CONSTRAINT vault_auth_vaults_pkey PRIMARY KEY (id);


--
-- Name: vaults vaults_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vaults
    ADD CONSTRAINT vaults_name_key UNIQUE (name);


--
-- Name: vaults vaults_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vaults
    ADD CONSTRAINT vaults_pkey PRIMARY KEY (id);


--
-- Name: vitals_code_classes_by_cluster vitals_code_classes_by_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_code_classes_by_cluster
    ADD CONSTRAINT vitals_code_classes_by_cluster_pkey PRIMARY KEY (code_class, duration, at);


--
-- Name: vitals_code_classes_by_workspace vitals_code_classes_by_workspace_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_code_classes_by_workspace
    ADD CONSTRAINT vitals_code_classes_by_workspace_pkey PRIMARY KEY (workspace_id, code_class, duration, at);


--
-- Name: vitals_codes_by_consumer_route vitals_codes_by_consumer_route_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_codes_by_consumer_route
    ADD CONSTRAINT vitals_codes_by_consumer_route_pkey PRIMARY KEY (consumer_id, route_id, code, duration, at);


--
-- Name: vitals_codes_by_route vitals_codes_by_route_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_codes_by_route
    ADD CONSTRAINT vitals_codes_by_route_pkey PRIMARY KEY (route_id, code, duration, at);


--
-- Name: vitals_locks vitals_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_locks
    ADD CONSTRAINT vitals_locks_pkey PRIMARY KEY (key);


--
-- Name: vitals_node_meta vitals_node_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_node_meta
    ADD CONSTRAINT vitals_node_meta_pkey PRIMARY KEY (node_id);


--
-- Name: vitals_stats_days vitals_stats_days_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_stats_days
    ADD CONSTRAINT vitals_stats_days_pkey PRIMARY KEY (node_id, at);


--
-- Name: vitals_stats_hours vitals_stats_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_stats_hours
    ADD CONSTRAINT vitals_stats_hours_pkey PRIMARY KEY (at);


--
-- Name: vitals_stats_minutes vitals_stats_minutes_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_stats_minutes
    ADD CONSTRAINT vitals_stats_minutes_pkey PRIMARY KEY (node_id, at);


--
-- Name: vitals_stats_seconds vitals_stats_seconds_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.vitals_stats_seconds
    ADD CONSTRAINT vitals_stats_seconds_pkey PRIMARY KEY (node_id, at);


--
-- Name: workspace_entities workspace_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.workspace_entities
    ADD CONSTRAINT workspace_entities_pkey PRIMARY KEY (workspace_id, entity_id, unique_field_name);


--
-- Name: workspace_entity_counters workspace_entity_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.workspace_entity_counters
    ADD CONSTRAINT workspace_entity_counters_pkey PRIMARY KEY (workspace_id, entity_type);


--
-- Name: workspaces workspaces_name_key; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_name_key UNIQUE (name);


--
-- Name: workspaces workspaces_pkey; Type: CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_pkey PRIMARY KEY (id);


--
-- Name: acls_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX acls_consumer_id_idx ON public.acls USING btree (consumer_id);


--
-- Name: acls_group_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX acls_group_idx ON public.acls USING btree ("group");


--
-- Name: acls_tags_idex_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX acls_tags_idex_tags_idx ON public.acls USING gin (tags);


--
-- Name: acme_storage_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX acme_storage_ttl_idx ON public.acme_storage USING btree (ttl);


--
-- Name: applications_developer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX applications_developer_id_idx ON public.applications USING btree (developer_id);


--
-- Name: audit_objects_request_timestamp_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX audit_objects_request_timestamp_idx ON public.audit_objects USING btree (request_timestamp);


--
-- Name: audit_objects_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX audit_objects_ttl_idx ON public.audit_objects USING btree (ttl);


--
-- Name: audit_requests_request_timestamp_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX audit_requests_request_timestamp_idx ON public.audit_requests USING btree (request_timestamp);


--
-- Name: audit_requests_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX audit_requests_ttl_idx ON public.audit_requests USING btree (ttl);


--
-- Name: basicauth_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX basicauth_consumer_id_idx ON public.basicauth_credentials USING btree (consumer_id);


--
-- Name: basicauth_tags_idex_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX basicauth_tags_idex_tags_idx ON public.basicauth_credentials USING gin (tags);


--
-- Name: certificates_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX certificates_tags_idx ON public.certificates USING gin (tags);


--
-- Name: cluster_events_at_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX cluster_events_at_idx ON public.cluster_events USING btree (at);


--
-- Name: cluster_events_channel_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX cluster_events_channel_idx ON public.cluster_events USING btree (channel);


--
-- Name: cluster_events_expire_at_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX cluster_events_expire_at_idx ON public.cluster_events USING btree (expire_at);


--
-- Name: clustering_data_planes_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX clustering_data_planes_ttl_idx ON public.clustering_data_planes USING btree (ttl);


--
-- Name: clustering_rpc_requests_node_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX clustering_rpc_requests_node_id_idx ON public.clustering_rpc_requests USING btree (node_id);


--
-- Name: consumer_group_consumers_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumer_group_consumers_consumer_id_idx ON public.consumer_group_consumers USING btree (consumer_id);


--
-- Name: consumer_group_consumers_group_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumer_group_consumers_group_id_idx ON public.consumer_group_consumers USING btree (consumer_group_id);


--
-- Name: consumer_group_plugins_group_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumer_group_plugins_group_id_idx ON public.consumer_group_plugins USING btree (consumer_group_id);


--
-- Name: consumer_group_plugins_plugin_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumer_group_plugins_plugin_name_idx ON public.consumer_group_plugins USING btree (name);


--
-- Name: consumer_groups_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumer_groups_name_idx ON public.consumer_groups USING btree (name);


--
-- Name: consumer_groups_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumer_groups_tags_idx ON public.consumer_groups USING gin (tags);


--
-- Name: consumer_reset_secrets_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumer_reset_secrets_consumer_id_idx ON public.consumer_reset_secrets USING btree (consumer_id);


--
-- Name: consumers_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumers_tags_idx ON public.consumers USING gin (tags);


--
-- Name: consumers_type_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumers_type_idx ON public.consumers USING btree (type);


--
-- Name: consumers_username_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX consumers_username_idx ON public.consumers USING btree (lower(username));


--
-- Name: credentials_consumer_id_plugin; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX credentials_consumer_id_plugin ON public.credentials USING btree (consumer_id, plugin);


--
-- Name: credentials_consumer_type; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX credentials_consumer_type ON public.credentials USING btree (consumer_id);


--
-- Name: degraphql_routes_fkey_service; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX degraphql_routes_fkey_service ON public.degraphql_routes USING btree (service_id);


--
-- Name: developers_rbac_user_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX developers_rbac_user_id_idx ON public.developers USING btree (rbac_user_id);


--
-- Name: files_path_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX files_path_idx ON public.files USING btree (path);


--
-- Name: filter_chains_cache_key_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE UNIQUE INDEX filter_chains_cache_key_idx ON public.filter_chains USING btree (cache_key);


--
-- Name: filter_chains_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE UNIQUE INDEX filter_chains_name_idx ON public.filter_chains USING btree (name);


--
-- Name: filter_chains_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX filter_chains_tags_idx ON public.filter_chains USING gin (tags);


--
-- Name: graphql_ratelimiting_advanced_cost_decoration_fkey_service; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX graphql_ratelimiting_advanced_cost_decoration_fkey_service ON public.graphql_ratelimiting_advanced_cost_decoration USING btree (service_id);


--
-- Name: groups_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX groups_name_idx ON public.groups USING btree (name);


--
-- Name: header_cert_auth_common_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX header_cert_auth_common_name_idx ON public.header_cert_auth_credentials USING btree (subject_name);


--
-- Name: header_cert_auth_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX header_cert_auth_consumer_id_idx ON public.header_cert_auth_credentials USING btree (consumer_id);


--
-- Name: header_cert_auth_credentials_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX header_cert_auth_credentials_tags_idx ON public.header_cert_auth_credentials USING gin (tags);


--
-- Name: hmacauth_credentials_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX hmacauth_credentials_consumer_id_idx ON public.hmacauth_credentials USING btree (consumer_id);


--
-- Name: hmacauth_tags_idex_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX hmacauth_tags_idex_tags_idx ON public.hmacauth_credentials USING gin (tags);


--
-- Name: jwt_secrets_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX jwt_secrets_consumer_id_idx ON public.jwt_secrets USING btree (consumer_id);


--
-- Name: jwt_secrets_secret_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX jwt_secrets_secret_idx ON public.jwt_secrets USING btree (secret);


--
-- Name: jwtsecrets_tags_idex_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX jwtsecrets_tags_idex_tags_idx ON public.jwt_secrets USING gin (tags);


--
-- Name: key_sets_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX key_sets_tags_idx ON public.key_sets USING gin (tags);


--
-- Name: keyauth_credentials_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keyauth_credentials_consumer_id_idx ON public.keyauth_credentials USING btree (consumer_id);


--
-- Name: keyauth_credentials_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keyauth_credentials_ttl_idx ON public.keyauth_credentials USING btree (ttl);


--
-- Name: keyauth_enc_credentials_consum; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keyauth_enc_credentials_consum ON public.keyauth_enc_credentials USING btree (consumer_id);


--
-- Name: keyauth_enc_credentials_ttl; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keyauth_enc_credentials_ttl ON public.keyauth_enc_credentials USING btree (ttl);


--
-- Name: keyauth_enc_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keyauth_enc_tags_idx ON public.keyauth_enc_credentials USING gin (tags);


--
-- Name: keyauth_tags_idex_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keyauth_tags_idex_tags_idx ON public.keyauth_credentials USING gin (tags);


--
-- Name: keys_fkey_key_sets; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keys_fkey_key_sets ON public.keys USING btree (set_id);


--
-- Name: keys_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX keys_tags_idx ON public.keys USING gin (tags);


--
-- Name: konnect_applications_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX konnect_applications_tags_idx ON public.konnect_applications USING gin (tags);


--
-- Name: legacy_files_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX legacy_files_name_idx ON public.legacy_files USING btree (name);


--
-- Name: license_data_key_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE UNIQUE INDEX license_data_key_idx ON public.license_data USING btree (node_id, year, month);


--
-- Name: locks_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX locks_ttl_idx ON public.locks USING btree (ttl);


--
-- Name: login_attempts_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX login_attempts_ttl_idx ON public.login_attempts USING btree (ttl);


--
-- Name: mtls_auth_common_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX mtls_auth_common_name_idx ON public.mtls_auth_credentials USING btree (subject_name);


--
-- Name: mtls_auth_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX mtls_auth_consumer_id_idx ON public.mtls_auth_credentials USING btree (consumer_id);


--
-- Name: mtls_auth_credentials_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX mtls_auth_credentials_tags_idx ON public.mtls_auth_credentials USING gin (tags);


--
-- Name: oauth2_authorization_codes_authenticated_userid_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_authorization_codes_authenticated_userid_idx ON public.oauth2_authorization_codes USING btree (authenticated_userid);


--
-- Name: oauth2_authorization_codes_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_authorization_codes_ttl_idx ON public.oauth2_authorization_codes USING btree (ttl);


--
-- Name: oauth2_authorization_credential_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_authorization_credential_id_idx ON public.oauth2_authorization_codes USING btree (credential_id);


--
-- Name: oauth2_authorization_service_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_authorization_service_id_idx ON public.oauth2_authorization_codes USING btree (service_id);


--
-- Name: oauth2_credentials_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_credentials_consumer_id_idx ON public.oauth2_credentials USING btree (consumer_id);


--
-- Name: oauth2_credentials_secret_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_credentials_secret_idx ON public.oauth2_credentials USING btree (client_secret);


--
-- Name: oauth2_credentials_tags_idex_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_credentials_tags_idex_tags_idx ON public.oauth2_credentials USING gin (tags);


--
-- Name: oauth2_tokens_authenticated_userid_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_tokens_authenticated_userid_idx ON public.oauth2_tokens USING btree (authenticated_userid);


--
-- Name: oauth2_tokens_credential_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_tokens_credential_id_idx ON public.oauth2_tokens USING btree (credential_id);


--
-- Name: oauth2_tokens_service_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_tokens_service_id_idx ON public.oauth2_tokens USING btree (service_id);


--
-- Name: oauth2_tokens_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX oauth2_tokens_ttl_idx ON public.oauth2_tokens USING btree (ttl);


--
-- Name: plugins_consumer_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX plugins_consumer_id_idx ON public.plugins USING btree (consumer_id);


--
-- Name: plugins_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX plugins_name_idx ON public.plugins USING btree (name);


--
-- Name: plugins_route_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX plugins_route_id_idx ON public.plugins USING btree (route_id);


--
-- Name: plugins_service_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX plugins_service_id_idx ON public.plugins USING btree (service_id);


--
-- Name: plugins_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX plugins_tags_idx ON public.plugins USING gin (tags);


--
-- Name: ratelimiting_metrics_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX ratelimiting_metrics_idx ON public.ratelimiting_metrics USING btree (service_id, route_id, period_date, period);


--
-- Name: ratelimiting_metrics_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX ratelimiting_metrics_ttl_idx ON public.ratelimiting_metrics USING btree (ttl);


--
-- Name: rbac_role_default_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX rbac_role_default_idx ON public.rbac_roles USING btree (is_default);


--
-- Name: rbac_role_endpoints_role_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX rbac_role_endpoints_role_idx ON public.rbac_role_endpoints USING btree (role_id);


--
-- Name: rbac_role_entities_role_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX rbac_role_entities_role_idx ON public.rbac_role_entities USING btree (role_id);


--
-- Name: rbac_roles_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX rbac_roles_name_idx ON public.rbac_roles USING btree (name);


--
-- Name: rbac_token_ident_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX rbac_token_ident_idx ON public.rbac_users USING btree (user_token_ident);


--
-- Name: rbac_users_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX rbac_users_name_idx ON public.rbac_users USING btree (name);


--
-- Name: rbac_users_token_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX rbac_users_token_idx ON public.rbac_users USING btree (user_token);


--
-- Name: routes_service_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX routes_service_id_idx ON public.routes USING btree (service_id);


--
-- Name: routes_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX routes_tags_idx ON public.routes USING gin (tags);


--
-- Name: services_fkey_client_certificate; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX services_fkey_client_certificate ON public.services USING btree (client_certificate_id);


--
-- Name: services_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX services_tags_idx ON public.services USING gin (tags);


--
-- Name: session_sessions_expires_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX session_sessions_expires_idx ON public.sessions USING btree (expires);


--
-- Name: sessions_ttl_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX sessions_ttl_idx ON public.sessions USING btree (ttl);


--
-- Name: sm_vaults_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX sm_vaults_tags_idx ON public.sm_vaults USING gin (tags);


--
-- Name: snis_certificate_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX snis_certificate_id_idx ON public.snis USING btree (certificate_id);


--
-- Name: snis_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX snis_tags_idx ON public.snis USING gin (tags);


--
-- Name: sync_key_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX sync_key_idx ON public.rl_counters USING btree (namespace, window_start);


--
-- Name: tags_entity_name_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX tags_entity_name_idx ON public.tags USING btree (entity_name);


--
-- Name: tags_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX tags_tags_idx ON public.tags USING gin (tags);


--
-- Name: targets_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX targets_tags_idx ON public.targets USING gin (tags);


--
-- Name: targets_target_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX targets_target_idx ON public.targets USING btree (target);


--
-- Name: targets_upstream_id_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX targets_upstream_id_idx ON public.targets USING btree (upstream_id);


--
-- Name: upstreams_fkey_client_certificate; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX upstreams_fkey_client_certificate ON public.upstreams USING btree (client_certificate_id);


--
-- Name: upstreams_tags_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX upstreams_tags_idx ON public.upstreams USING gin (tags);


--
-- Name: vcbr_svc_ts_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX vcbr_svc_ts_idx ON public.vitals_codes_by_route USING btree (service_id, duration, at);


--
-- Name: workspace_entities_composite_idx; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX workspace_entities_composite_idx ON public.workspace_entities USING btree (workspace_id, entity_type, unique_field_name);


--
-- Name: workspace_entities_idx_entity_id; Type: INDEX; Schema: public; Owner: kong
--

CREATE INDEX workspace_entities_idx_entity_id ON public.workspace_entities USING btree (entity_id);


--
-- Name: acls acls_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER acls_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.acls FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: acme_storage acme_storage_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER acme_storage_ttl_trigger AFTER INSERT ON public.acme_storage FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('ttl');


--
-- Name: basicauth_credentials basicauth_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER basicauth_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.basicauth_credentials FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: ca_certificates ca_certificates_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER ca_certificates_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.ca_certificates FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: certificates certificates_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER certificates_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.certificates FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: cluster_events cluster_events_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER cluster_events_ttl_trigger AFTER INSERT ON public.cluster_events FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('expire_at');


--
-- Name: clustering_data_planes clustering_data_planes_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER clustering_data_planes_ttl_trigger AFTER INSERT ON public.clustering_data_planes FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('ttl');


--
-- Name: consumer_groups consumer_groups_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER consumer_groups_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.consumer_groups FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: consumers consumers_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER consumers_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.consumers FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: filter_chains filter_chains_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER filter_chains_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.filter_chains FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: header_cert_auth_credentials header_cert_auth_credentials_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER header_cert_auth_credentials_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.header_cert_auth_credentials FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: hmacauth_credentials hmacauth_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER hmacauth_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.hmacauth_credentials FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: jwt_secrets jwtsecrets_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER jwtsecrets_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.jwt_secrets FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: key_sets key_sets_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER key_sets_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.key_sets FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: keyauth_credentials keyauth_credentials_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER keyauth_credentials_ttl_trigger AFTER INSERT ON public.keyauth_credentials FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('ttl');


--
-- Name: keyauth_enc_credentials keyauth_enc_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER keyauth_enc_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.keyauth_enc_credentials FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: keyauth_credentials keyauth_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER keyauth_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.keyauth_credentials FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: keys keys_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER keys_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.keys FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: konnect_applications konnect_applications_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER konnect_applications_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.konnect_applications FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: mtls_auth_credentials mtls_auth_credentials_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER mtls_auth_credentials_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.mtls_auth_credentials FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER oauth2_authorization_codes_ttl_trigger AFTER INSERT ON public.oauth2_authorization_codes FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('ttl');


--
-- Name: oauth2_credentials oauth2_credentials_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER oauth2_credentials_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.oauth2_credentials FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: oauth2_tokens oauth2_tokens_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER oauth2_tokens_ttl_trigger AFTER INSERT ON public.oauth2_tokens FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('ttl');


--
-- Name: plugins plugins_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER plugins_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.plugins FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: ratelimiting_metrics ratelimiting_metrics_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER ratelimiting_metrics_ttl_trigger AFTER INSERT ON public.ratelimiting_metrics FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('ttl');


--
-- Name: routes routes_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER routes_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.routes FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: services services_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER services_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.services FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: sessions sessions_ttl_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER sessions_ttl_trigger AFTER INSERT ON public.sessions FOR EACH STATEMENT EXECUTE FUNCTION public.batch_delete_expired_rows('ttl');


--
-- Name: sm_vaults sm_vaults_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER sm_vaults_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.sm_vaults FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: snis snis_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER snis_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.snis FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: targets targets_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER targets_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.targets FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: upstreams upstreams_sync_tags_trigger; Type: TRIGGER; Schema: public; Owner: kong
--

CREATE TRIGGER upstreams_sync_tags_trigger AFTER INSERT OR DELETE OR UPDATE OF tags ON public.upstreams FOR EACH ROW EXECUTE FUNCTION public.sync_tags();


--
-- Name: acls acls_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.acls
    ADD CONSTRAINT acls_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: acls acls_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.acls
    ADD CONSTRAINT acls_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: admins admins_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_consumer_id_fkey FOREIGN KEY (consumer_id) REFERENCES public.consumers(id);


--
-- Name: admins admins_rbac_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_rbac_user_id_fkey FOREIGN KEY (rbac_user_id) REFERENCES public.rbac_users(id);


--
-- Name: application_instances application_instances_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.application_instances
    ADD CONSTRAINT application_instances_application_id_fkey FOREIGN KEY (application_id, ws_id) REFERENCES public.applications(id, ws_id);


--
-- Name: application_instances application_instances_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.application_instances
    ADD CONSTRAINT application_instances_service_id_fkey FOREIGN KEY (service_id, ws_id) REFERENCES public.services(id, ws_id);


--
-- Name: application_instances application_instances_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.application_instances
    ADD CONSTRAINT application_instances_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: applications applications_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id);


--
-- Name: applications applications_developer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_developer_id_fkey FOREIGN KEY (developer_id, ws_id) REFERENCES public.developers(id, ws_id);


--
-- Name: applications applications_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: basicauth_credentials basicauth_credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.basicauth_credentials
    ADD CONSTRAINT basicauth_credentials_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: basicauth_credentials basicauth_credentials_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.basicauth_credentials
    ADD CONSTRAINT basicauth_credentials_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: certificates certificates_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.certificates
    ADD CONSTRAINT certificates_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: consumer_group_consumers consumer_group_consumers_consumer_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_consumers
    ADD CONSTRAINT consumer_group_consumers_consumer_group_id_fkey FOREIGN KEY (consumer_group_id) REFERENCES public.consumer_groups(id) ON DELETE CASCADE;


--
-- Name: consumer_group_consumers consumer_group_consumers_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_consumers
    ADD CONSTRAINT consumer_group_consumers_consumer_id_fkey FOREIGN KEY (consumer_id) REFERENCES public.consumers(id) ON DELETE CASCADE;


--
-- Name: consumer_group_plugins consumer_group_plugins_consumer_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_plugins
    ADD CONSTRAINT consumer_group_plugins_consumer_group_id_fkey FOREIGN KEY (consumer_group_id, ws_id) REFERENCES public.consumer_groups(id, ws_id) ON DELETE CASCADE;


--
-- Name: consumer_group_plugins consumer_group_plugins_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_group_plugins
    ADD CONSTRAINT consumer_group_plugins_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: consumer_groups consumer_groups_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_groups
    ADD CONSTRAINT consumer_groups_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: consumer_reset_secrets consumer_reset_secrets_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumer_reset_secrets
    ADD CONSTRAINT consumer_reset_secrets_consumer_id_fkey FOREIGN KEY (consumer_id) REFERENCES public.consumers(id) ON DELETE CASCADE;


--
-- Name: consumers consumers_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.consumers
    ADD CONSTRAINT consumers_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: credentials credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_consumer_id_fkey FOREIGN KEY (consumer_id) REFERENCES public.consumers(id) ON DELETE CASCADE;


--
-- Name: degraphql_routes degraphql_routes_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.degraphql_routes
    ADD CONSTRAINT degraphql_routes_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: developers developers_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id);


--
-- Name: developers developers_rbac_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_rbac_user_id_fkey FOREIGN KEY (rbac_user_id, ws_id) REFERENCES public.rbac_users(id, ws_id);


--
-- Name: developers developers_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.developers
    ADD CONSTRAINT developers_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: document_objects document_objects_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.document_objects
    ADD CONSTRAINT document_objects_service_id_fkey FOREIGN KEY (service_id, ws_id) REFERENCES public.services(id, ws_id);


--
-- Name: document_objects document_objects_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.document_objects
    ADD CONSTRAINT document_objects_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: files files_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: filter_chains filter_chains_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.filter_chains
    ADD CONSTRAINT filter_chains_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.routes(id) ON DELETE CASCADE;


--
-- Name: filter_chains filter_chains_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.filter_chains
    ADD CONSTRAINT filter_chains_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: filter_chains filter_chains_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.filter_chains
    ADD CONSTRAINT filter_chains_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: graphql_ratelimiting_advanced_cost_decoration graphql_ratelimiting_advanced_cost_decoration_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.graphql_ratelimiting_advanced_cost_decoration
    ADD CONSTRAINT graphql_ratelimiting_advanced_cost_decoration_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: group_rbac_roles group_rbac_roles_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.group_rbac_roles
    ADD CONSTRAINT group_rbac_roles_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_rbac_roles group_rbac_roles_rbac_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.group_rbac_roles
    ADD CONSTRAINT group_rbac_roles_rbac_role_id_fkey FOREIGN KEY (rbac_role_id) REFERENCES public.rbac_roles(id) ON DELETE CASCADE;


--
-- Name: group_rbac_roles group_rbac_roles_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.group_rbac_roles
    ADD CONSTRAINT group_rbac_roles_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: header_cert_auth_credentials header_cert_auth_credentials_ca_certificate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.header_cert_auth_credentials
    ADD CONSTRAINT header_cert_auth_credentials_ca_certificate_id_fkey FOREIGN KEY (ca_certificate_id) REFERENCES public.ca_certificates(id) ON DELETE CASCADE;


--
-- Name: header_cert_auth_credentials header_cert_auth_credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.header_cert_auth_credentials
    ADD CONSTRAINT header_cert_auth_credentials_consumer_id_fkey FOREIGN KEY (consumer_id) REFERENCES public.consumers(id) ON DELETE CASCADE;


--
-- Name: header_cert_auth_credentials header_cert_auth_credentials_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.header_cert_auth_credentials
    ADD CONSTRAINT header_cert_auth_credentials_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id);


--
-- Name: hmacauth_credentials hmacauth_credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.hmacauth_credentials
    ADD CONSTRAINT hmacauth_credentials_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: hmacauth_credentials hmacauth_credentials_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.hmacauth_credentials
    ADD CONSTRAINT hmacauth_credentials_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: jwt_secrets jwt_secrets_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.jwt_secrets
    ADD CONSTRAINT jwt_secrets_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: jwt_secrets jwt_secrets_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.jwt_secrets
    ADD CONSTRAINT jwt_secrets_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: key_sets key_sets_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.key_sets
    ADD CONSTRAINT key_sets_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: keyauth_credentials keyauth_credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_credentials
    ADD CONSTRAINT keyauth_credentials_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: keyauth_credentials keyauth_credentials_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_credentials
    ADD CONSTRAINT keyauth_credentials_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: keyauth_enc_credentials keyauth_enc_credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_enc_credentials
    ADD CONSTRAINT keyauth_enc_credentials_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: keyauth_enc_credentials keyauth_enc_credentials_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keyauth_enc_credentials
    ADD CONSTRAINT keyauth_enc_credentials_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id);


--
-- Name: keys keys_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.key_sets(id) ON DELETE CASCADE;


--
-- Name: keys keys_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: konnect_applications konnect_applications_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.konnect_applications
    ADD CONSTRAINT konnect_applications_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id);


--
-- Name: login_attempts login_attempts_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.login_attempts
    ADD CONSTRAINT login_attempts_consumer_id_fkey FOREIGN KEY (consumer_id) REFERENCES public.consumers(id) ON DELETE CASCADE;


--
-- Name: mtls_auth_credentials mtls_auth_credentials_ca_certificate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.mtls_auth_credentials
    ADD CONSTRAINT mtls_auth_credentials_ca_certificate_id_fkey FOREIGN KEY (ca_certificate_id) REFERENCES public.ca_certificates(id) ON DELETE CASCADE;


--
-- Name: mtls_auth_credentials mtls_auth_credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.mtls_auth_credentials
    ADD CONSTRAINT mtls_auth_credentials_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: mtls_auth_credentials mtls_auth_credentials_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.mtls_auth_credentials
    ADD CONSTRAINT mtls_auth_credentials_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id);


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_credential_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_authorization_codes
    ADD CONSTRAINT oauth2_authorization_codes_credential_id_fkey FOREIGN KEY (credential_id, ws_id) REFERENCES public.oauth2_credentials(id, ws_id) ON DELETE CASCADE;


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_plugin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_authorization_codes
    ADD CONSTRAINT oauth2_authorization_codes_plugin_id_fkey FOREIGN KEY (plugin_id) REFERENCES public.plugins(id) ON DELETE CASCADE;


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_authorization_codes
    ADD CONSTRAINT oauth2_authorization_codes_service_id_fkey FOREIGN KEY (service_id, ws_id) REFERENCES public.services(id, ws_id) ON DELETE CASCADE;


--
-- Name: oauth2_authorization_codes oauth2_authorization_codes_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_authorization_codes
    ADD CONSTRAINT oauth2_authorization_codes_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: oauth2_credentials oauth2_credentials_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_credentials
    ADD CONSTRAINT oauth2_credentials_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: oauth2_credentials oauth2_credentials_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_credentials
    ADD CONSTRAINT oauth2_credentials_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: oauth2_tokens oauth2_tokens_credential_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_tokens
    ADD CONSTRAINT oauth2_tokens_credential_id_fkey FOREIGN KEY (credential_id, ws_id) REFERENCES public.oauth2_credentials(id, ws_id) ON DELETE CASCADE;


--
-- Name: oauth2_tokens oauth2_tokens_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_tokens
    ADD CONSTRAINT oauth2_tokens_service_id_fkey FOREIGN KEY (service_id, ws_id) REFERENCES public.services(id, ws_id) ON DELETE CASCADE;


--
-- Name: oauth2_tokens oauth2_tokens_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.oauth2_tokens
    ADD CONSTRAINT oauth2_tokens_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: plugins plugins_consumer_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_consumer_group_id_fkey FOREIGN KEY (consumer_group_id) REFERENCES public.consumer_groups(id) ON DELETE CASCADE;


--
-- Name: plugins plugins_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_consumer_id_fkey FOREIGN KEY (consumer_id, ws_id) REFERENCES public.consumers(id, ws_id) ON DELETE CASCADE;


--
-- Name: plugins plugins_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_route_id_fkey FOREIGN KEY (route_id, ws_id) REFERENCES public.routes(id, ws_id) ON DELETE CASCADE;


--
-- Name: plugins plugins_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_service_id_fkey FOREIGN KEY (service_id, ws_id) REFERENCES public.services(id, ws_id) ON DELETE CASCADE;


--
-- Name: plugins plugins_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.plugins
    ADD CONSTRAINT plugins_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: rbac_role_endpoints rbac_role_endpoints_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_role_endpoints
    ADD CONSTRAINT rbac_role_endpoints_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.rbac_roles(id) ON DELETE CASCADE;


--
-- Name: rbac_role_entities rbac_role_entities_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_role_entities
    ADD CONSTRAINT rbac_role_entities_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.rbac_roles(id) ON DELETE CASCADE;


--
-- Name: rbac_roles rbac_roles_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_roles
    ADD CONSTRAINT rbac_roles_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: rbac_user_groups rbac_user_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_user_groups
    ADD CONSTRAINT rbac_user_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: rbac_user_groups rbac_user_groups_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_user_groups
    ADD CONSTRAINT rbac_user_groups_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.rbac_users(id) ON DELETE CASCADE;


--
-- Name: rbac_user_roles rbac_user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_user_roles
    ADD CONSTRAINT rbac_user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.rbac_roles(id) ON DELETE CASCADE;


--
-- Name: rbac_user_roles rbac_user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_user_roles
    ADD CONSTRAINT rbac_user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.rbac_users(id) ON DELETE CASCADE;


--
-- Name: rbac_users rbac_users_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.rbac_users
    ADD CONSTRAINT rbac_users_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: routes routes_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_service_id_fkey FOREIGN KEY (service_id, ws_id) REFERENCES public.services(id, ws_id);


--
-- Name: routes routes_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: services services_client_certificate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_client_certificate_id_fkey FOREIGN KEY (client_certificate_id, ws_id) REFERENCES public.certificates(id, ws_id);


--
-- Name: services services_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: sm_vaults sm_vaults_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.sm_vaults
    ADD CONSTRAINT sm_vaults_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: snis snis_certificate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.snis
    ADD CONSTRAINT snis_certificate_id_fkey FOREIGN KEY (certificate_id, ws_id) REFERENCES public.certificates(id, ws_id);


--
-- Name: snis snis_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.snis
    ADD CONSTRAINT snis_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: targets targets_upstream_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_upstream_id_fkey FOREIGN KEY (upstream_id, ws_id) REFERENCES public.upstreams(id, ws_id) ON DELETE CASCADE;


--
-- Name: targets targets_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: upstreams upstreams_client_certificate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.upstreams
    ADD CONSTRAINT upstreams_client_certificate_id_fkey FOREIGN KEY (client_certificate_id) REFERENCES public.certificates(id);


--
-- Name: upstreams upstreams_ws_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.upstreams
    ADD CONSTRAINT upstreams_ws_id_fkey FOREIGN KEY (ws_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: workspace_entity_counters workspace_entity_counters_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kong
--

ALTER TABLE ONLY public.workspace_entity_counters
    ADD CONSTRAINT workspace_entity_counters_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 13.16 (Debian 13.16-1.pgdg120+1)
-- Dumped by pg_dump version 13.16 (Debian 13.16-1.pgdg120+1)

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

DROP DATABASE postgres;
--
-- Name: postgres; Type: DATABASE; Schema: -; Owner: kong
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE postgres OWNER TO kong;

\connect postgres

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

--
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: kong
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

