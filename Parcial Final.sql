-- DDL para el Modelo de Campeonatos de Fútbol

-- Tabla Pais
CREATE TABLE Pais (
    Id INT PRIMARY KEY,
    NombrePais VARCHAR(100) NOT NULL UNIQUE,
    Bandera TEXT, -- URL o dato binario
    LogoEntidad TEXT -- URL o dato binario
);

-- Tabla Ciudad
CREATE TABLE Ciudad (
    Id INT PRIMARY KEY,
    NombreCiudad VARCHAR(100) NOT NULL,
    IdPais INT NOT NULL,
    FOREIGN KEY (IdPais) REFERENCES Pais(Id)
);

-- Tabla Estadio
CREATE TABLE Estadio (
    Id INT PRIMARY KEY,
    NombreEstadio VARCHAR(100) NOT NULL,
    Capacidad INT,
    IdCiudad INT NOT NULL,
    Foto TEXT,
    FOREIGN KEY (IdCiudad) REFERENCES Ciudad(Id)
);

-- Tabla Campeonato
CREATE TABLE Campeonato (
    Id INT PRIMARY KEY,
    NombreCampeonato VARCHAR(100) NOT NULL,
    Anio INT,
    IdPaisAnfitrion INT NOT NULL,
    FOREIGN KEY (IdPaisAnfitrion) REFERENCES Pais(Id)
);

-- Tabla Grupo
CREATE TABLE Grupo (
    Id INT PRIMARY KEY,
    NombreGrupo VARCHAR(10) NOT NULL, -- Ej: 'A', 'B', 'H', 'Final'
    IdCampeonato INT NOT NULL,
    FOREIGN KEY (IdCampeonato) REFERENCES Campeonato(Id)
);

-- Tabla GrupoPais (Tabla de relación N:M entre Grupo y Pais)
CREATE TABLE GrupoPais (
    IdGrupo INT NOT NULL,
    IdPais INT NOT NULL,
    PRIMARY KEY (IdGrupo, IdPais),
    FOREIGN KEY (IdGrupo) REFERENCES Grupo(Id),
    FOREIGN KEY (IdPais) REFERENCES Pais(Id)
);

-- Tabla Fase
CREATE TABLE Fase (
    Id INT PRIMARY KEY,
    NombreFase VARCHAR(50) NOT NULL, -- Ej: 'Fase de Grupos', 'Octavos', 'Cuartos'
    IdCampeonato INT NOT NULL,
    FOREIGN KEY (IdCampeonato) REFERENCES Campeonato(Id)
);

-- Tabla Encuentro
CREATE TABLE Encuentro (
    Id INT PRIMARY KEY,
    IdPais1 INT NOT NULL,
    IdPais2 INT NOT NULL,
    IdEstadio INT,
    IdFase INT NOT NULL,
    Fecha TIMESTAMP NOT NULL,
    Goles1 INT, -- Goles del País 1
    Goles2 INT, -- Goles del País 2
    FOREIGN KEY (IdPais1) REFERENCES Pais(Id),
    FOREIGN KEY (IdPais2) REFERENCES Pais(Id),
    FOREIGN KEY (IdEstadio) REFERENCES Estadio(Id),
    FOREIGN KEY (IdFase) REFERENCES Fase(Id)
);

-- Función de Tabla para obtener la Tabla de Posiciones de un Grupo

CREATE OR REPLACE FUNCTION fTablaPosicionesGrupo(id_grupo_param INT)
RETURNS TABLE (
    id INT, -- Mapea al ID del País para el DTO en Java
    pais VARCHAR,
    pj INT,
    pg INT,
    pe INT,
    pp INT,
    gf INT,
    gc INT,
    puntos INT
)
AS $$
BEGIN
    RETURN QUERY
    WITH ResultadosPais AS (
        -- 1. Obtener todos los encuentros donde participa un país del grupo
        SELECT
            gp.idpais,
            p.nombrepais,
            e.goles1,
            e.goles2,
            e.idpais1,
            e.idpais2
        FROM
            grupopais gp
        JOIN
            pais p ON gp.idpais = p.id
        JOIN
            grupo g ON gp.idgrupo = g.id
        JOIN
            fase f ON g.idcampeonato = f.idcampeonato
        JOIN
            encuentro e ON e.idfase = f.id
        WHERE
            gp.idgrupo = id_grupo_param
            AND (gp.idpais = e.idpais1 OR gp.idpais = e.idpais2)
    )
    SELECT
        rp.idpais AS id,
        rp.nombrepais AS pais,
        COUNT(*) AS pj, -- Partidos Jugados
        SUM(
            CASE
                -- Si es el país 1 y ganó (Goles1 > Goles2) O es el país 2 y ganó (Goles2 > Goles1)
                WHEN (rp.idpais = rp.idpais1 AND rp.goles1 > rp.goles2) OR (rp.idpais = rp.idpais2 AND rp.goles2 > rp.goles1)
                THEN 1
                ELSE 0
            END
        ) AS pg, -- Partidos Ganados
        SUM(
            CASE
                -- Si empató (Goles1 = Goles2)
                WHEN rp.goles1 = rp.goles2
                THEN 1
                ELSE 0
            END
        ) AS pe, -- Partidos Empatados
        SUM(
            CASE
                -- Si es el país 1 y perdió (Goles1 < Goles2) O es el país 2 y perdió (Goles2 < Goles1)
                WHEN (rp.idpais = rp.idpais1 AND rp.goles1 < rp.goles2) OR (rp.idpais = rp.idpais2 AND rp.goles2 < rp.goles1)
                THEN 1
                ELSE 0
            END
        ) AS pp, -- Partidos Perdidos
        SUM(
            CASE
                -- Si es el país 1, Goles a Favor es Goles1, sino Goles2
                WHEN rp.idpais = rp.idpais1 THEN rp.goles1
                ELSE rp.goles2
            END
        ) AS gf, -- Goles a Favor
        SUM(
            CASE
                -- Si es el país 1, Goles en Contra es Goles2, sino Goles1
                WHEN rp.idpais = rp.idpais1 THEN rp.goles2
                ELSE rp.goles1
            END
        ) AS gc, -- Goles en Contra
        SUM(
            CASE
                -- Ganado: 3 puntos
                WHEN (rp.idpais = rp.idpais1 AND rp.goles1 > rp.goles2) OR (rp.idpais = rp.idpais2 AND rp.goles2 > rp.goles1) THEN 3
                -- Empatado: 1 punto
                WHEN rp.goles1 = rp.goles2 THEN 1
                -- Perdido: 0 puntos
                ELSE 0
            END
        ) AS puntos -- Puntos Totales
    FROM
        ResultadosPais rp
    GROUP BY
        rp.idpais, rp.nombrepais
    ORDER BY
        puntos DESC,
        (gf - gc) DESC, -- Desempate por diferencia de goles
        gf DESC; -- Desempate por goles a favor
END;
$$
LANGUAGE plpgsql;

-- DDL para el Modelo de Monedas y Cambios

-- Tabla Moneda
CREATE TABLE Moneda (
    Id INT PRIMARY KEY,
    NombreMoneda VARCHAR(50) NOT NULL UNIQUE,
    Simbolo VARCHAR(5) NOT NULL
);

-- Tabla Cambio
-- Se asume un modelo donde el cambio es respecto a una moneda base implícita (ej: USD) o un cambio respecto a otra moneda base.
-- Siguiendo la interpretación simple del diagrama que solo muestra IdMoneda.
CREATE TABLE Cambio (
    Id INT PRIMARY KEY,
    IdMoneda INT NOT NULL, -- Moneda a la que aplica el cambio
    Fecha DATE NOT NULL,
    Valor DECIMAL(10, 4) NOT NULL, -- Valor de la moneda respecto a la base
    FOREIGN KEY (IdMoneda) REFERENCES Moneda(Id)
);

-- Si se requiere un modelo de cambio entre dos monedas específicas (Origen y Destino):
/*
CREATE TABLE Cambio (
    Id INT PRIMARY KEY,
    IdMonedaOrigen INT NOT NULL,
    IdMonedaDestino INT NOT NULL,
    Fecha DATE NOT NULL,
    Valor DECIMAL(10, 4) NOT NULL, -- Valor de 1 unidad de Origen en Destino
    FOREIGN KEY (IdMonedaOrigen) REFERENCES Moneda(Id),
    FOREIGN KEY (IdMonedaDestino) REFERENCES Moneda(Id),
    UNIQUE (IdMonedaOrigen, IdMonedaDestino, Fecha)
);
*/