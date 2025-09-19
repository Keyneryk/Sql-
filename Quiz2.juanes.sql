SELECT COUNT(*) AS NumCanciones
FROM Cancion
WHERE CHARINDEX('JUANES', Compositor) > 0;

SELECT a.Seudonimo AS Interprete, r.Nombre AS Ritmo
FROM Cancion c
JOIN Interpretacion i ON c.CancionID = i.CancionID
JOIN Artista a ON i.ArtistaID = a.ArtistaID
JOIN Ritmo r ON c.RitmoID = r.RitmoID
WHERE c.Titulo = 'Lluvia';

SELECT DISTINCT c.Titulo,
       a.Seudonimo AS Interprete,
       c.Compositor
FROM Cancion c
JOIN Interpretacion i ON c.CancionID = i.CancionID
JOIN Artista a ON i.ArtistaID = a.ArtistaID
JOIN Ritmo r ON c.RitmoID = r.RitmoID
WHERE r.Nombre = 'Balada'
  AND a.Tipo = 'Cantante' -- o algún valor que indique que no es grupo
  AND CHARINDEX(a.Seudonimo, c.Compositor) > 0;

  SELECT DISTINCT a.Pais
FROM Artista a
JOIN Interpretacion i ON a.ArtistaID = i.ArtistaID
JOIN Cancion c ON i.CancionID = c.CancionID
JOIN Ritmo r ON c.RitmoID = r.RitmoID
WHERE r.Nombre = 'Salsa'
  AND a.Tipo = 'Grupo';

  SELECT c.Titulo, a.Seudonimo AS Interprete
FROM Cancion c
JOIN Interpretacion i ON c.CancionID = i.CancionID
JOIN Artista a ON i.ArtistaID = a.ArtistaID
WHERE c.Titulo IN ('Candilejas', 'Malaguena')
ORDER BY c.Titulo, a.Seudonimo;

SELECT a.Seudonimo,
       COUNT(DISTINCT ci.CancionID) AS CancionesInterpretadas,
       COUNT(DISTINCT cc.CancionID) AS CancionesCompuestas
FROM Artista a
LEFT JOIN Interpretacion ci ON a.ArtistaID = ci.ArtistaID
LEFT JOIN Cancion cc ON CHARINDEX(a.Seudonimo, cc.Compositor) > 0
GROUP BY a.Seudonimo
HAVING COUNT(DISTINCT ci.CancionID) > 0
   AND COUNT(DISTINCT cc.CancionID) > 0
ORDER BY CancionesCompuestas DESC, CancionesInterpretadas DESC;
