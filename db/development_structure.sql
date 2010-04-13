--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: problems; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE problems (
    id integer NOT NULL,
    subject text,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reporter_id integer,
    stop_id integer
);


--
-- Name: problems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE problems_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: problems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE problems_id_seq OWNED BY problems.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: stop_area_memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stop_area_memberships (
    id integer NOT NULL,
    stop_id integer,
    stop_area_id integer,
    creation_datetime timestamp without time zone,
    modification_datetime timestamp without time zone,
    revision_number integer,
    modification character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: stop_area_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stop_area_memberships_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: stop_area_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stop_area_memberships_id_seq OWNED BY stop_area_memberships.id;


--
-- Name: stop_areas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stop_areas (
    id integer NOT NULL,
    code character varying(255),
    name text,
    administrative_area_code character varying(255),
    area_type character varying(255),
    grid_type character varying(255),
    easting double precision,
    northing double precision,
    creation_datetime timestamp without time zone,
    modification_datetime timestamp without time zone,
    revision_number integer,
    modification character varying(255),
    status character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: stop_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stop_areas_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: stop_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stop_areas_id_seq OWNED BY stop_areas.id;


--
-- Name: stop_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stop_types (
    id integer NOT NULL,
    code character varying(255),
    description character varying(255),
    on_street boolean,
    mode character varying(255),
    point_type character varying(255),
    version double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: stop_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stop_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: stop_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stop_types_id_seq OWNED BY stop_types.id;


--
-- Name: stops; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stops (
    id integer NOT NULL,
    atco_code character varying(255),
    naptan_code character varying(255),
    plate_code character varying(255),
    common_name text,
    short_common_name text,
    landmark text,
    street text,
    crossing text,
    indicator text,
    bearing character varying(255),
    nptg_locality_code character varying(255),
    locality_name character varying(255),
    parent_locality_name character varying(255),
    grand_parent_locality_name character varying(255),
    town character varying(255),
    suburb character varying(255),
    locality_centre boolean,
    grid_type character varying(255),
    easting double precision,
    northing double precision,
    lon double precision,
    lat double precision,
    stop_type character varying(255),
    bus_stop_type character varying(255),
    administrative_area_code character varying(255),
    creation_datetime timestamp without time zone,
    modification_datetime timestamp without time zone,
    revision_number integer,
    modification character varying(255),
    status character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: stops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stops_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: stops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stops_id_seq OWNED BY stops.id;


--
-- Name: transport_modes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transport_modes (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: transport_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transport_modes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: transport_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transport_modes_id_seq OWNED BY transport_modes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(255),
    email character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE problems ALTER COLUMN id SET DEFAULT nextval('problems_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE stop_area_memberships ALTER COLUMN id SET DEFAULT nextval('stop_area_memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE stop_areas ALTER COLUMN id SET DEFAULT nextval('stop_areas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE stop_types ALTER COLUMN id SET DEFAULT nextval('stop_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE stops ALTER COLUMN id SET DEFAULT nextval('stops_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE transport_modes ALTER COLUMN id SET DEFAULT nextval('transport_modes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: problems_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY problems
    ADD CONSTRAINT problems_pkey PRIMARY KEY (id);


--
-- Name: stop_area_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stop_area_memberships
    ADD CONSTRAINT stop_area_memberships_pkey PRIMARY KEY (id);


--
-- Name: stop_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stop_areas
    ADD CONSTRAINT stop_areas_pkey PRIMARY KEY (id);


--
-- Name: stop_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stop_types
    ADD CONSTRAINT stop_types_pkey PRIMARY KEY (id);


--
-- Name: stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stops
    ADD CONSTRAINT stops_pkey PRIMARY KEY (id);


--
-- Name: transport_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transport_modes
    ADD CONSTRAINT transport_modes_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_stop_area_memberships_on_stop_area_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stop_area_memberships_on_stop_area_id ON stop_area_memberships USING btree (stop_area_id);


--
-- Name: index_stop_area_memberships_on_stop_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stop_area_memberships_on_stop_id ON stop_area_memberships USING btree (stop_id);


--
-- Name: index_stop_areas_on_code_lower; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stop_areas_on_code_lower ON stop_areas USING btree (lower((code)::text));


--
-- Name: index_stops_on_atco_code_lower; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stops_on_atco_code_lower ON stops USING btree (lower((atco_code)::text));


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: problems_reporter_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY problems
    ADD CONSTRAINT problems_reporter_id_fk FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- Name: stop_area_memberships_stop_area_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stop_area_memberships
    ADD CONSTRAINT stop_area_memberships_stop_area_id_fk FOREIGN KEY (stop_area_id) REFERENCES stop_areas(id);


--
-- Name: stop_area_memberships_stop_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stop_area_memberships
    ADD CONSTRAINT stop_area_memberships_stop_id_fk FOREIGN KEY (stop_id) REFERENCES stops(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20100407110848');

INSERT INTO schema_migrations (version) VALUES ('20100407171321');

INSERT INTO schema_migrations (version) VALUES ('20100408111344');

INSERT INTO schema_migrations (version) VALUES ('20100408120352');

INSERT INTO schema_migrations (version) VALUES ('20100408150322');

INSERT INTO schema_migrations (version) VALUES ('20100408151525');

INSERT INTO schema_migrations (version) VALUES ('20100408155400');

INSERT INTO schema_migrations (version) VALUES ('20100408164042');

INSERT INTO schema_migrations (version) VALUES ('20100408173847');

INSERT INTO schema_migrations (version) VALUES ('20100413102606');

INSERT INTO schema_migrations (version) VALUES ('20100413110049');