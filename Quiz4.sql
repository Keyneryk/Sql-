CREATE OR ALTER PROCEDURE spGenerarEncuentrosOctavos
    @IdCampeonato INT,
    @IdEstadio INT = NULL  -- Estadio predeterminado opcional
AS 
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que existan grupos en el campeonato
    IF NOT EXISTS (SELECT 1 FROM Grupo WHERE IdCampeonato = @IdCampeonato)
    BEGIN
        RAISERROR('El campeonato no tiene grupos asignados.', 16, 1);
        RETURN;
    END;
    
    -- Validar que existan encuentros de fase de grupos (IdFase = 1)
    IF NOT EXISTS (SELECT 1 FROM Encuentro WHERE IdCampeonato = @IdCampeonato AND IdFase = 1)
    BEGIN
        RAISERROR('No existen encuentros de fase de grupos para este campeonato.', 16, 1);
        RETURN;
    END;
    
    -- CTE para calcular la tabla de posiciones de cada grupo
    WITH TablaPosiciones AS (
        SELECT 
            gp.IdGrupo,
            gp.IdPais,
            g.Grupo,
            -- Calcular puntos (victoria = 3, empate = 1, derrota = 0)
            SUM(CASE 
                WHEN e.IdPais1 = gp.IdPais AND e.Goles1 > e.Goles2 THEN 3
                WHEN e.IdPais2 = gp.IdPais AND e.Goles2 > e.Goles1 THEN 3
                WHEN e.IdPais1 = gp.IdPais AND e.Goles1 = e.Goles2 THEN 1
                WHEN e.IdPais2 = gp.IdPais AND e.Goles1 = e.Goles2 THEN 1
                ELSE 0
            END) AS Puntos,
            -- Calcular diferencia de goles
            SUM(CASE 
                WHEN e.IdPais1 = gp.IdPais THEN e.Goles1 - e.Goles2
                WHEN e.IdPais2 = gp.IdPais THEN e.Goles2 - e.Goles1
                ELSE 0
            END) AS DiferenciaGoles,
            -- Calcular goles a favor
            SUM(CASE 
                WHEN e.IdPais1 = gp.IdPais THEN e.Goles1
                WHEN e.IdPais2 = gp.IdPais THEN e.Goles2
                ELSE 0
            END) AS GolesFavor
        FROM GrupoPais gp
        INNER JOIN Grupo g ON gp.IdGrupo = g.Id
        INNER JOIN Encuentro e ON (e.IdPais1 = gp.IdPais OR e.IdPais2 = gp.IdPais)
            AND e.IdCampeonato = @IdCampeonato
            AND e.IdFase = 1  -- Solo fase de grupos
            AND e.Goles1 IS NOT NULL  -- Solo encuentros jugados
            AND e.Goles2 IS NOT NULL
        WHERE g.IdCampeonato = @IdCampeonato
        GROUP BY gp.IdGrupo, gp.IdPais, g.Grupo
    ),
    -- CTE para ordenar y rankear los equipos dentro de cada grupo
    PosicionesRankeadas AS (
        SELECT 
            IdGrupo,
            IdPais,
            Grupo,
            Puntos,
            DiferenciaGoles,
            GolesFavor,
            ROW_NUMBER() OVER (
                PARTITION BY IdGrupo 
                ORDER BY Puntos DESC, DiferenciaGoles DESC, GolesFavor DESC
            ) AS Posicion
        FROM TablaPosiciones
    ),
    -- CTE para obtener los primeros dos de cada grupo
    PrimerosSegundos AS (
        SELECT 
            IdGrupo,
            IdPais,
            Grupo,
            Posicion
        FROM PosicionesRankeadas
        WHERE Posicion <= 2
    ),
    -- CTE para emparejar grupos (A con B, C con D, E con F, etc.)
    Emparejamientos AS (
        SELECT 
            g1.IdGrupo AS IdGrupo1,
            g1.Grupo AS Grupo1,
            g2.IdGrupo AS IdGrupo2,
            g2.Grupo AS Grupo2,
            ROW_NUMBER() OVER (ORDER BY g1.Grupo) AS NumPareja
        FROM (SELECT DISTINCT IdGrupo, Grupo FROM PrimerosSegundos) g1
        INNER JOIN (SELECT DISTINCT IdGrupo, Grupo FROM PrimerosSegundos) g2 
            ON g1.Grupo < g2.Grupo
            AND (ASCII(g1.Grupo) + 1 = ASCII(g2.Grupo))  -- Empareja grupos consecutivos
    ),
    -- CTE para generar los cruces de octavos
    CrucesOctavos AS (
        -- Primer cruce: 1ro del Grupo1 vs 2do del Grupo2
        SELECT 
            p1.IdPais AS IdPais1,
            p2.IdPais AS IdPais2
        FROM Emparejamientos e
        INNER JOIN PrimerosSegundos p1 ON p1.IdGrupo = e.IdGrupo1 AND p1.Posicion = 1
        INNER JOIN PrimerosSegundos p2 ON p2.IdGrupo = e.IdGrupo2 AND p2.Posicion = 2
        
        UNION ALL
        
        -- Segundo cruce: 1ro del Grupo2 vs 2do del Grupo1
        SELECT 
            p1.IdPais AS IdPais1,
            p2.IdPais AS IdPais2
        FROM Emparejamientos e
        INNER JOIN PrimerosSegundos p1 ON p1.IdGrupo = e.IdGrupo2 AND p1.Posicion = 1
        INNER JOIN PrimerosSegundos p2 ON p2.IdGrupo = e.IdGrupo1 AND p2.Posicion = 2
    )
    -- Insertar los encuentros de octavos que no existen
    INSERT INTO Encuentro (IdPais1, IdPais2, IdFase, IdCampeonato, IdEstadio)
    SELECT 
        c.IdPais1, 
        c.IdPais2, 
        2,  -- IdFase = 2 para octavos de final
        @IdCampeonato, 
        ISNULL(@IdEstadio, (SELECT TOP 1 Id FROM Estadio))  -- Estadio predeterminado
    FROM CrucesOctavos c
    WHERE NOT EXISTS (
        SELECT 1 FROM Encuentro e
        WHERE e.IdCampeonato = @IdCampeonato
            AND e.IdFase = 2
            AND ((e.IdPais1 = c.IdPais1 AND e.IdPais2 = c.IdPais2)
                OR (e.IdPais1 = c.IdPais2 AND e.IdPais2 = c.IdPais1))
    );
    
    PRINT 'Encuentros de octavos generados correctamente para el campeonato ' + 
          CAST(@IdCampeonato AS VARCHAR);
END
GO