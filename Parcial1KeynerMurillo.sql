-- a. Trigger para validar que una regi�n no tenga m�s de una ciudad capital
CREATE TRIGGER tActualizarCapitalRegion
ON Ciudad
FOR INSERT, UPDATE
AS BEGIN
    --Validar que se est� actualizando una capital de regi�n
    IF EXISTS(SELECT * FROM Inserted WHERE CapitalRegion=1)
    BEGIN
        -- Verificar si la inserci�n o actualizaci�n causar�a que
        -- haya m�s de una capital de regi�n
        IF EXISTS(SELECT 1
                 FROM Inserted I
                 JOIN Ciudad C ON I.IdRegion=C.IdRegion
                 WHERE I.CapitalRegion=1 AND 
                       C.CapitalRegion=1 AND C.Id<>I.Id
                 GROUP BY I.IdRegion
                 HAVING COUNT(*) > 1)
        BEGIN
            RAISERROR('No se acepta m�s de una capital por regi�n', 16, 1)
            ROLLBACK TRANSACTION
        END

        -- Si se est� estableciendo una ciudad como capital,
        -- asegurarse de que las dem�s no lo sean
        UPDATE Ciudad
        SET CapitalRegion=0
        FROM Ciudad C
        JOIN Inserted I ON C.IdRegion=I.IdRegion
        AND C.Id<>I.Id
    END
END
GO

-- b. Trigger para validar que un pa�s no tenga m�s de una ciudad capital
CREATE TRIGGER tActualizarCapitalPais
ON Ciudad
FOR INSERT, UPDATE
AS
BEGIN
    -- Evitar ejecuci�n recursiva del trigger
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;
    
    -- Asegurarnos de que solo quede una ciudad como CapitalPais = 1 por cada Pa�s
    WITH UltimaCapital AS (
        SELECT C.Id, R.IdPais
        FROM Inserted I
        JOIN Ciudad C ON C.Id=I.Id
        JOIN Region R ON C.IdRegion=R.Id
        WHERE I.CapitalPais=1
    )
    UPDATE C
    SET C.CapitalPais = CASE WHEN C.Id=U.Id THEN 1 ELSE 0 END
    FROM Ciudad C
    JOIN Region R ON C.IdRegion=R.Id
    JOIN UltimaCapital U ON U.IdPais = R.IdPais
END;
GO;

-- Trigger para validar que un pa�s no figure en m�s de un grupo de un campeonato
CREATE TRIGGER tActualizarGrupoPais
ON GrupoPais
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si alg�n pa�s de la inserci�n/actualizaci�n
    -- ya est� en otro grupo del mismo campeonato
    IF EXISTS(
        SELECT 1
        FROM Inserted I
        JOIN Grupo GNuevo ON GNuevo.Id = I.IdGrupo
        JOIN GrupoPais GP ON GP.IdPais = I.IdPais
        JOIN Grupo GExistente ON GExistente.Id = GP.IdGrupo
        WHERE GNuevo.IdCampeonato = GExistente.IdCampeonato
        AND GNuevo.Id <> GExistente.Id
    )
    BEGIN
        -- Cancelar la instrucci�n y lanzar error
        RAISERROR('Un pa�s no puede pertenecer a m�s de un grupo en el mismo campeonato.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- Trigger para validar que en un mismo campeonato y fase, 
-- un encuentro entre dos pa�ses no se repita
CREATE TRIGGER tValidarEncuentroUnico
ON Encuentro
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si ya existe un encuentro entre los mismos pa�ses
    -- en la misma fase y campeonato (considerando ambas direcciones)
    IF EXISTS(
        SELECT 1
        FROM Inserted I
        JOIN Encuentro E ON (
            -- Misma fase y campeonato
            E.IdFase = I.IdFase
            AND E.IdCampeonato = I.IdCampeonato
            -- Mismo encuentro en cualquier direcci�n (A vs B o B vs A)
            AND (
                (E.IdPaisLocal = I.IdPaisLocal AND E.IdPaisVisitante = I.IdPaisVisitante)
                OR 
                (E.IdPaisLocal = I.IdPaisVisitante AND E.IdPaisVisitante = I.IdPaisLocal)
            )
            -- Excluir el registro que se est� actualizando
            AND E.Id <> I.Id
        )
    )
    BEGIN
        RAISERROR('Ya existe un encuentro entre estos pa�ses en la misma fase del campeonato.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Validaci�n adicional: Un pa�s no puede jugar contra s� mismo
    IF EXISTS(
        SELECT 1 
        FROM Inserted I 
        WHERE I.IdPaisLocal = I.IdPaisVisitante
    )
    BEGIN
        RAISERROR('Un pa�s no puede jugar contra s� mismo.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO



