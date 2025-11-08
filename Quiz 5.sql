CREATE FUNCTION fTablaPosiciones(@idGrupo int)
RETURNS @TablaPosiciones TABLE(
  IdPais int,
  Pais varchar(100),
  PJ int,
  PG int,
  PE int,
  PP int,
  GF int,
  GC int,
  Puntos int
)
AS
BEGIN
  INSERT INTO @TablaPosiciones
  SELECT 
    P.Id, P.Pais, COUNT(*),
    SUM(CASE WHEN (P.Id=E.IdPais1 AND Goles1>Goles2) OR (P.Id=E.IdPais2 AND Goles2>Goles1) THEN 1 ELSE 0 END),
    SUM(CASE WHEN (P.Id=E.IdPais1 AND Goles1=Goles2) OR (P.Id=E.IdPais2 AND Goles2=Goles1) THEN 1 ELSE 0 END),
    SUM(CASE WHEN (P.Id=E.IdPais1 AND Goles1<Goles2) OR (P.Id=E.IdPais2 AND Goles2<Goles1) THEN 1 ELSE 0 END),
    SUM(CASE WHEN P.Id=E.IdPais1 THEN Goles1 ELSE Goles2 END),
    SUM(CASE WHEN P.Id=E.IdPais1 THEN Goles2 ELSE Goles1 END),
    SUM(CASE 
      WHEN P.Id=E.IdPais1 AND Goles1>Goles2 THEN 3
      WHEN P.Id=E.IdPais2 AND Goles2>Goles1 THEN 3
      WHEN Goles2=Goles1 THEN 1
      ELSE 0
    END)
  FROM GrupoPais GP
  JOIN Pais P ON GP.IdPais=P.Id
  JOIN Encuentro E ON (P.Id=E.IdPais1 OR P.Id=E.IdPais2)
  WHERE GP.IdGrupo=@idGrupo AND E.IdFase=1
  GROUP BY P.Id, P.Pais

  RETURN
END;


CREATE FUNCTION fTraduceFrase(@frase varchar(MAX), @idIdiomaDestino int)
RETURNS @Traduccion TABLE (
    FragmentoOriginal varchar(100),
    FragmentoTraducido varchar(100)
)
AS
BEGIN
    DECLARE @fraseTemp varchar(MAX) = @frase;
    DECLARE @pos int;
    DECLARE @palabra varchar(100);

    WHILE LEN(@fraseTemp) > 0
    BEGIN
        SET @pos = CHARINDEX(' ', @fraseTemp);
        IF @pos > 0
        BEGIN
            SET @palabra = LEFT(@fraseTemp, @pos - 1);
            SET @fraseTemp = SUBSTRING(@fraseTemp, @pos + 1, LEN(@fraseTemp));
        END
        ELSE
        BEGIN
            SET @palabra = @fraseTemp;
            SET @fraseTemp = '';
        END

        INSERT INTO @Traduccion
        SELECT @palabra, ISNULL(t.Traducido, @palabra)
        FROM Traduccion t
        WHERE t.Espanol = @palabra AND t.IdIdioma = @idIdiomaDestino;
    END

    RETURN;
END;

CREATE FUNCTION fCancionesPorRitmo(@ritmo varchar(50))
RETURNS TABLE
AS
RETURN
(
    SELECT IdCancion, Titulo, Ritmo
    FROM Cancion
    WHERE Ritmo = @ritmo
);
