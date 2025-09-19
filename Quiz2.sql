SELECT COUNT(*) AS NumCanciones
FROM Cancion
WHERE CHARINDEX('Michael Anthony Torres Monge', Compositor) > 0;

SELECT a.Seudonimo AS Interprete, r.Nombre AS Ritmo
FROM Cancion c
JOIN Interpretacion i ON c.CancionID = i.CancionID
JOIN Artista a ON i.ArtistaID = a.ArtistaID
JOIN Ritmo r ON c.RitmoID = r.RitmoID
WHERE c.Titulo = 'Caramelo';

SELECT DISTINCT c.Titulo, a.Seudonimo AS Interprete, c.Compositor
FROM Cancion c
JOIN Interpretacion i ON c.CancionID = i.CancionID
JOIN Artista a ON i.ArtistaID = a.ArtistaID
JOIN Ritmo r ON c.RitmoID = r.RitmoID
WHERE r.Nombre = 'Trap'
  AND a.Seudonimo = 'Myke Towers'
  AND CHARINDEX('Michael Anthony Torres Monge', c.Compositor) > 0;

SELECT DISTINCT a.Pais
FROM Artista a
JOIN Interpretacion i ON a.ArtistaID = i.ArtistaID
JOIN Cancion c ON i.CancionID = c.CancionID
JOIN Ritmo r ON c.RitmoID = r.RitmoID
WHERE r.Nombre = 'Reguetón'
  AND a.Tipo = 'Grupo';

  SELECT c.Titulo, a.Seudonimo AS Interprete
FROM Cancion c
JOIN Interpretacion i ON c.CancionID = i.CancionID
JOIN Artista a ON i.ArtistaID = a.ArtistaID
WHERE c.Titulo IN ('Caramelo', 'La Luz')
ORDER BY c.Titulo, a.Seudonimo;

SELECT a.Seudonimo,
       COUNT(DISTINCT ci.CancionID) AS CancionesInterpretadas,
       COUNT(DISTINCT cc.CancionID) AS CancionesCompuestas
FROM Artista a
LEFT JOIN Interpretacion ci ON a.ArtistaID = ci.ArtistaID
LEFT JOIN Cancion cc ON CHARINDEX(a.NombreReal, cc.Compositor) > 0
GROUP BY a.Seudonimo
HAVING COUNT(DISTINCT ci.CancionID) > 0
   AND COUNT(DISTINCT cc.CancionID) > 0
ORDER BY CancionesCompuestas DESC, CancionesInterpretadas DESC;
