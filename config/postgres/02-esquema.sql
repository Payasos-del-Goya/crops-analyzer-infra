-- Esquema de la base de datos fieldshift (pg_dump de la Raspberry, 15-11-2026). Lo crea fieldshift_app.
SET ROLE fieldshift_app;
--
-- PostgreSQL database dump
--


-- Dumped from database version 17.12 (Debian 17.12-0+deb13u1)
-- Dumped by pg_dump version 17.12 (Debian 17.12-0+deb13u1)

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: balizas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.balizas (
    id text NOT NULL,
    cliente_id text NOT NULL,
    latitud numeric(9,6),
    longitud numeric(9,6),
    cultivo_id integer,
    creado timestamp with time zone DEFAULT now() NOT NULL,
    label text,
    zona text,
    textura_suelo text,
    altitud_m numeric(6,1),
    CONSTRAINT balizas_check CHECK (((latitud IS NULL) = (longitud IS NULL))),
    CONSTRAINT balizas_id_check CHECK ((id ~ '^b[0-9A-Fa-f]{2,}'::text)),
    CONSTRAINT balizas_latitud_check CHECK (((latitud >= ('-90'::integer)::numeric) AND (latitud <= (90)::numeric))),
    CONSTRAINT balizas_longitud_check CHECK (((longitud >= ('-180'::integer)::numeric) AND (longitud <= (180)::numeric))),
    CONSTRAINT balizas_textura_suelo_check CHECK ((textura_suelo = ANY (ARRAY['arenoso'::text, 'franco'::text, 'arcilloso'::text])))
);


--
-- Name: COLUMN balizas.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.balizas.id IS 'Igual que el tag dispositivo de InfluxDB ("b" + 3 últimos bytes de la MAC, p. ej. bA78B10)';


--
-- Name: COLUMN balizas.cliente_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.balizas.cliente_id IS 'Igual que el prefijo de los buckets de InfluxDB (c001)';


--
-- Name: COLUMN balizas.cultivo_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.balizas.cultivo_id IS 'Cultivo que vigila la baliza (valores ideales en cultivos)';


--
-- Name: COLUMN balizas.label; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.balizas.label IS 'Etiqueta visible de la baliza en el mapa/panel (p. ej. "A")';


--
-- Name: COLUMN balizas.zona; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.balizas.zona IS 'soto, vega, terraza, regadio, secano, saladar...';


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id text NOT NULL,
    nombre text,
    creado timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT clientes_id_check CHECK ((id ~ '^c[0-9]{3}$'::text))
);


--
-- Name: cultivos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cultivos (
    id integer NOT NULL,
    grupo text,
    cultivo text NOT NULL,
    referencia_fao56 text,
    kc_ini numeric,
    kc_mid_min numeric,
    kc_mid_max numeric,
    kc_end_min numeric,
    kc_end_max numeric,
    altura_min_m numeric,
    altura_max_m numeric,
    zr_min_m numeric,
    zr_max_m numeric,
    p_agotamiento numeric,
    cee_umbral_min_ds_m numeric,
    cee_umbral_max_ds_m numeric,
    b_min_pct_por_ds_m numeric,
    b_max_pct_por_ds_m numeric,
    tolerancia_salinidad text,
    ky_min numeric,
    ky_max numeric,
    l_ini_d numeric,
    l_des_d numeric,
    l_med_d numeric,
    l_fin_d numeric,
    total_fases_d numeric,
    region_siembra_fases text,
    notas text,
    nombre_cientifico text,
    ciclo_vida text,
    origen_bloque_fao56 text,
    fiabilidad_agro text,
    temp_aire_opt_min_c numeric,
    temp_aire_opt_max_c numeric,
    temp_aire_min_abs_c numeric,
    temp_aire_max_abs_c numeric,
    temp_letal_helada_c numeric,
    periodo_sensible_helada text,
    prob_helada_suelo_sensibilidad text,
    temp_suelo_siembra_min_c numeric,
    gdd_base_c numeric,
    gdd_acum_ciclo_min numeric,
    gdd_acum_ciclo_max numeric,
    horas_frio_min_h numeric,
    horas_frio_max_h numeric,
    luz_solar_tipo text,
    luz_solar_dli_min_mol_m2_d numeric,
    luz_solar_dli_opt_mol_m2_d numeric,
    fotoperiodo text,
    radiacion_mj_min_m2_d numeric,
    radiacion_mj_opt_m2_d numeric,
    hr_opt_min_pct numeric,
    hr_opt_max_pct numeric,
    hr_riesgo_enfermedad_pct numeric,
    hoja_mojada_horas_riesgo numeric,
    hoja_mojada_enfermedad_ref text,
    conductividad_us_umbral_cee_min numeric,
    conductividad_us_umbral_cee_max numeric,
    conductividad_us_cee_rend0 numeric,
    conductividad_us_agua_riego_max numeric,
    conductividad_us_solucion_opt_min numeric,
    conductividad_us_solucion_opt_max numeric,
    et0_mm_dia_tipico_fase_media numeric,
    etc_mm_dia_pico numeric,
    smi_umbral_riego numeric,
    smi_15_umbral_riego numeric,
    smi_50_umbral_riego numeric,
    smi_ks50 numeric,
    smi_sensor_control_cm text,
    taw_mm_arenoso numeric,
    taw_mm_franco numeric,
    taw_mm_arcilloso numeric,
    deficit_mm_umbral_arenoso numeric,
    deficit_mm_umbral_franco numeric,
    deficit_mm_umbral_arcilloso numeric,
    viento_ms_ref_u2 numeric,
    viento_ms_danio numeric,
    viento_ms_polinizacion_max numeric,
    precip_anual_opt_min_mm numeric,
    precip_anual_opt_max_mm numeric,
    precip_anual_abs_min_mm numeric,
    precip_anual_abs_max_mm numeric,
    ph_opt_min numeric,
    ph_opt_max numeric,
    ph_abs_min numeric,
    ph_abs_max numeric
);


--
-- Name: TABLE cultivos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.cultivos IS 'Valores ideales por cultivo (cultivos_fao56_ampliado_datos.csv). Ver cultivos_leyenda.';


--
-- Name: cultivos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cultivos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cultivos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cultivos_leyenda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cultivos_leyenda (
    orden integer NOT NULL,
    columna text NOT NULL,
    columna_original text NOT NULL,
    grupo text,
    descripcion text,
    unidad text,
    origen text,
    formula_o_nota text
);


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    usuario text NOT NULL,
    cliente_id text NOT NULL,
    password_hash text NOT NULL,
    creado timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT usuarios_usuario_check CHECK ((usuario ~ '^[a-z0-9_.-]{3,32}$'::text))
);


--
-- Name: balizas balizas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balizas
    ADD CONSTRAINT balizas_pkey PRIMARY KEY (id);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);


--
-- Name: cultivos cultivos_cultivo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cultivos
    ADD CONSTRAINT cultivos_cultivo_key UNIQUE (cultivo);


--
-- Name: cultivos_leyenda cultivos_leyenda_columna_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cultivos_leyenda
    ADD CONSTRAINT cultivos_leyenda_columna_key UNIQUE (columna);


--
-- Name: cultivos_leyenda cultivos_leyenda_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cultivos_leyenda
    ADD CONSTRAINT cultivos_leyenda_pkey PRIMARY KEY (orden);


--
-- Name: cultivos cultivos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cultivos
    ADD CONSTRAINT cultivos_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (usuario);


--
-- Name: balizas_cliente_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX balizas_cliente_idx ON public.balizas USING btree (cliente_id);


--
-- Name: usuarios_cliente_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX usuarios_cliente_idx ON public.usuarios USING btree (cliente_id);


--
-- Name: balizas balizas_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balizas
    ADD CONSTRAINT balizas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE;


--
-- Name: balizas balizas_cultivo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balizas
    ADD CONSTRAINT balizas_cultivo_id_fkey FOREIGN KEY (cultivo_id) REFERENCES public.cultivos(id);


--
-- Name: usuarios usuarios_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE;


--
-- PostgreSQL database dump complete
--


