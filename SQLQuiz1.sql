--Crear la base de datos
CREATE DATABASE SistemaBibliografico
GO

--Ir a la base de datos
USE SistemaBibliografico

--Crear la tabla País
CREATE TABLE Pais (
    IdPais INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    CodigoAlfa VARCHAR(3),
    Indicativo VARCHAR(10)
);

--Crear la Tabla TipoPublicacion
CREATE TABLE TipoPublicacion (
    IdTipoPublicacion INT AUTO_INCREMENT PRIMARY KEY,
    NombreTipo VARCHAR(50) NOT NULL UNIQUE
);

--Crear la Tabla Formato  
CREATE TABLE Formato (
    IdFormato INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL UNIQUE
);

--Crear la Tabla Autor
CREATE TABLE Autor (
    IdAutor INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100),
    TipoAutor ENUM('Individual', 'Corporativo') NOT NULL DEFAULT 'Individual'
);

--Crear la Tabla Descriptor
CREATE TABLE Descriptor (
    IdDescriptor INT AUTO_INCREMENT PRIMARY KEY,
    NombreDescriptor VARCHAR(100) NOT NULL UNIQUE,
    Descripcion TEXT
);

--Crear la Tabla Serie
CREATE TABLE Serie (
    IdSerie INT AUTO_INCREMENT PRIMARY KEY,
    NombreSerie VARCHAR(200) NOT NULL,
    ISSN VARCHAR(9),
    Periodicidad VARCHAR(50)
);

--Crear la Tabla Ciudad (depende de País)
CREATE TABLE Ciudad (
    IdCiudad INT AUTO_INCREMENT PRIMARY KEY,
    NombreCiudad VARCHAR(100) NOT NULL,
    IdPais INT NOT NULL,
    CONSTRAINT FK_Ciudad_Pais FOREIGN KEY (IdPais) REFERENCES Pais(IdPais)
);

--Crear la Tabla Volumen (depende de Serie)
CREATE TABLE Volumen (
    IdVolumen INT AUTO_INCREMENT PRIMARY KEY,
    NumeroVolumen INT NOT NULL,
    AnioVolumen YEAR NOT NULL,
    IdSerie INT NOT NULL,
    CONSTRAINT FK_Volumen_Serie FOREIGN KEY (IdSerie) REFERENCES Serie(IdSerie),
    UNIQUE KEY UK_Serie_Volumen_Anio (IdSerie, NumeroVolumen, AnioVolumen)
);

--Crear la Tabla Editorial (depende de Ciudad)
CREATE TABLE Editorial (
    IdEditorial INT AUTO_INCREMENT PRIMARY KEY,
    NombreEditorial VARCHAR(200) NOT NULL,
    Direccion VARCHAR(300),
    Telefono VARCHAR(20),
    IdCiudad INT NOT NULL,
    CONSTRAINT FK_Editorial_Ciudad FOREIGN KEY (IdCiudad) REFERENCES Ciudad(IdCiudad)
);

--Crear la Tabla Publicacion (entidad central)
CREATE TABLE Publicacion (
    IdPublicacion INT AUTO_INCREMENT PRIMARY KEY,
    Titulo VARCHAR(500) NOT NULL,
    Subtitulo VARCHAR(300),
    ISBN VARCHAR(17),
    AnioPublicacion YEAR NOT NULL,
    NumeroPaginas INT,
    Idioma VARCHAR(50) DEFAULT 'Español',
    Descripcion TEXT,
    
    --Claves foráneas obligatorias
    IdTipoPublicacion INT NOT NULL,
    IdEditorial INT NOT NULL,
    IdFormato INT NOT NULL,
    
    --Claves foráneas opcionales (para publicaciones seriadas)
    IdSerie INT,
    IdVolumen INT,
    NumeroEjemplar INT,
    
    -- Restricciones de clave foránea
    CONSTRAINT FK_Publicacion_TipoPublicacion 
        FOREIGN KEY (IdTipoPublicacion) REFERENCES TipoPublicacion(IdTipoPublicacion),
    CONSTRAINT FK_Publicacion_Editorial 
        FOREIGN KEY (IdEditorial) REFERENCES Editorial(IdEditorial),
    CONSTRAINT FK_Publicacion_Formato 
        FOREIGN KEY (IdFormato) REFERENCES Formato(IdFormato),
    CONSTRAINT FK_Publicacion_Serie 
        FOREIGN KEY (IdSerie) REFERENCES Serie(IdSerie),
    CONSTRAINT FK_Publicacion_Volumen 
        FOREIGN KEY (IdVolumen) REFERENCES Volumen(IdVolumen)
);

--Crear la tabla Relación Publicacion - Autor (M:N)
CREATE TABLE PublicacionAutor (
    IdPublicacion INT NOT NULL,
    IdAutor INT NOT NULL,
    OrdenAutoria INT DEFAULT 1,
    TipoContribucion VARCHAR(50) DEFAULT 'Autor',
    
    PRIMARY KEY (IdPublicacion, IdAutor),
    CONSTRAINT FK_PubAutor_Publicacion 
        FOREIGN KEY (IdPublicacion) REFERENCES Publicacion(IdPublicacion) ON DELETE CASCADE,
    CONSTRAINT FK_PubAutor_Autor 
        FOREIGN KEY (IdAutor) REFERENCES Autor(IdAutor)
);

--Crear la Relación Publicacion - Descriptor (M:N)
CREATE TABLE PublicacionDescriptor (
    IdPublicacion INT NOT NULL,
    IdDescriptor INT NOT NULL,
    Relevancia ENUM('Alta', 'Media', 'Baja') DEFAULT 'Media',
    
    PRIMARY KEY (IdPublicacion, IdDescriptor),
    CONSTRAINT FK_PubDesc_Publicacion 
        FOREIGN KEY (IdPublicacion) REFERENCES Publicacion(IdPublicacion) ON DELETE CASCADE,
    CONSTRAINT FK_PubDesc_Descriptor 
        FOREIGN KEY (IdDescriptor) REFERENCES Descriptor(IdDescriptor)
);

CREATE INDEX IDX_Publicacion_Titulo ON Publicacion(Titulo);
CREATE INDEX IDX_Publicacion_Anio ON Publicacion(AnioPublicacion);
CREATE INDEX IDX_Publicacion_ISBN ON Publicacion(ISBN);
CREATE INDEX IDX_Autor_Nombre ON Autor(Nombre, Apellido);
CREATE INDEX IDX_Descriptor_Nombre ON Descriptor(NombreDescriptor);

--Insertar países
INSERT INTO Pais (Nombre, CodigoAlfa, Indicativo) VALUES 
('Colombia', 'COL', '+57'),
('España', 'ESP', '+34'),
('México', 'MEX', '+52'),
('Argentina', 'ARG', '+54');

--Insertar ciudades
INSERT INTO Ciudad (NombreCiudad, IdPais) VALUES 
('Bogotá', 1),
('Medellín', 1),
('Madrid', 2),
('Barcelona', 2),
('Ciudad de México', 3),
('Buenos Aires', 4);

--Insertar tipos de publicación
INSERT INTO TipoPublicacion (NombreTipo) VALUES 
('Libro'),
('Revista Científica'),
('Tesis Doctoral'),
('Tesis de Maestría'),
('Periódico'),
('Artículo de Revista');

--Insertar formatos
INSERT INTO Formato (Nombre) VALUES 
('Físico'),
('Digital'),
('PDF'),
('E-Book'),
('Impreso');

--Insertar editoriales
INSERT INTO Editorial (NombreEditorial, Direccion, Telefono, IdCiudad) VALUES 
('Editorial Planeta Colombia', 'Calle 123 #45-67', '601-234-5678', 1),
('Fondo de Cultura Económica', 'Av. Universidad 975', '55-5227-4672', 5),
('Editorial Crítica', 'Provença 260', '93-492-8000', 4),
('Siglo XXI Editores', 'Guatemala 4824', '11-4832-1478', 6);

--Insertar autores
INSERT INTO Autor (Nombre, Apellido, TipoAutor) VALUES 
('Gabriel', 'García Márquez', 'Individual'),
('Mario', 'Vargas Llosa', 'Individual'),
('Octavio', 'Paz', 'Individual'),
('Universidad Nacional de Colombia', '', 'Corporativo'),
('Real Academia Española', '', 'Corporativo');

--Insertar descriptores
INSERT INTO Descriptor (NombreDescriptor, Descripcion) VALUES 
('Literatura Latinoamericana', 'Obras literarias de América Latina'),
('Realismo Mágico', 'Corriente literaria que combina realidad y fantasía'),
('Novela Contemporánea', 'Narrativa moderna'),
('Investigación Académica', 'Trabajos de investigación'),
('Lingüística', 'Estudios del lenguaje'),
('Historia de Colombia', 'Obras sobre historia nacional');

--Insertar series
INSERT INTO Serie (NombreSerie, ISSN, Periodicidad) VALUES 
('Revista de Literatura Colombiana', '1234-5678', 'Semestral'),
('Cuadernos de Historia', '8765-4321', 'Trimestral'),
('Estudios de Lingüística', '1111-2222', 'Anual');

--Insertar volúmenes
INSERT INTO Volumen (NumeroVolumen, AnioVolumen, IdSerie) VALUES 
(25, 2024, 1),
(30, 2024, 2),
(15, 2024, 3);

--Insertar publicaciones
INSERT INTO Publicacion (Titulo, Subtitulo, ISBN, AnioPublicacion, NumeroPaginas, IdTipoPublicacion, IdEditorial, IdFormato) VALUES 
('Cien años de soledad', NULL, '978-84-376-0494-7', 1967, 471, 1, 1, 1),
('La ciudad y los perros', NULL, '978-84-663-2764-1', 1963, 413, 1, 3, 1),
('El laberinto de la soledad', 'Ensayo sobre la identidad mexicana', '978-968-16-0123-4', 1950, 191, 1, 2, 1);

--Insertar artículo de revista
INSERT INTO Publicacion (Titulo, AnioPublicacion, NumeroPaginas, IdTipoPublicacion, IdEditorial, IdFormato, IdSerie, IdVolumen, NumeroEjemplar) VALUES 
('El nuevo realismo en la narrativa colombiana', 2024, 25, 6, 1, 3, 1, 1, 3);

--Relacionar publicaciones con autores
INSERT INTO PublicacionAutor (IdPublicacion, IdAutor, OrdenAutoria) VALUES 
(1, 1, 1),  -- García Márquez - Cien años de soledad
(2, 2, 1),  -- Vargas Llosa - La ciudad y los perros  
(3, 3, 1),  -- Octavio Paz - El laberinto
(4, 4, 1);  -- Universidad Nacional - artículo

--Relacionar publicaciones con descriptores
INSERT INTO PublicacionDescriptor (IdPublicacion, IdDescriptor, Relevancia) VALUES 
(1, 1, 'Alta'),    -- Cien años - Literatura Latinoamericana
(1, 2, 'Alta'),    -- Cien años - Realismo Mágico
(2, 1, 'Alta'),    -- La ciudad - Literatura Latinoamericana
(2, 3, 'Media'),   -- La ciudad - Novela Contemporánea
(3, 6, 'Alta'),    -- El laberinto - Historia (México/Latinoamérica)
(4, 4, 'Alta');    -- Artículo - Investigación Académica

--Ver todas las publicaciones con información completa
SELECT 
    p.Titulo,
    p.AnioPublicacion,
    tp.NombreTipo AS TipoPublicacion,
    f.Nombre AS Formato,
    e.NombreEditorial,
    c.NombreCiudad,
    pa.Nombre AS Pais
FROM Publicacion p
    JOIN TipoPublicacion tp ON p.IdTipoPublicacion = tp.IdTipoPublicacion
    JOIN Formato f ON p.IdFormato = f.IdFormato
    JOIN Editorial e ON p.IdEditorial = e.IdEditorial
    JOIN Ciudad c ON e.IdCiudad = c.IdCiudad
    JOIN Pais pa ON c.IdPais = pa.IdPais;

--Ver autores por publicación
SELECT 
    p.Titulo,
    CASE 
        WHEN a.TipoAutor = 'Individual' THEN CONCAT(a.Nombre, ' ', COALESCE(a.Apellido, ''))
        ELSE a.Nombre
    END AS AutorCompleto,
    a.TipoAutor,
    pa.OrdenAutoria
FROM Publicacion p
    JOIN PublicacionAutor pa ON p.IdPublicacion = pa.IdPublicacion
    JOIN Autor a ON pa.IdAutor = a.IdAutor
ORDER BY p.IdPublicacion, pa.OrdenAutoria;

--Ver publicaciones por descriptor
SELECT 
    d.NombreDescriptor,
    p.Titulo,
    p.AnioPublicacion,
    pd.Relevancia
FROM Descriptor d
    JOIN PublicacionDescriptor pd ON d.IdDescriptor = pd.IdDescriptor
    JOIN Publicacion p ON pd.IdPublicacion = p.IdPublicacion
ORDER BY d.NombreDescriptor, p.AnioPublicacion DESC;

--Ver publicaciones seriadas (revistas)
SELECT 
    p.Titulo,
    s.NombreSerie,
    s.ISSN,
    v.NumeroVolumen,
    v.AnioVolumen,
    p.NumeroEjemplar,
    s.Periodicidad
FROM Publicacion p
    JOIN Serie s ON p.IdSerie = s.IdSerie
    JOIN Volumen v ON p.IdVolumen = v.IdVolumen
WHERE p.IdSerie IS NOT NULL;

--Búsqueda de publicaciones por autor (ejemplo: García Márquez)
SELECT 
    p.Titulo,
    p.AnioPublicacion,
    tp.NombreTipo,
    CONCAT(a.Nombre, ' ', COALESCE(a.Apellido, '')) AS Autor
FROM Publicacion p
    JOIN PublicacionAutor pa ON p.IdPublicacion = pa.IdPublicacion
    JOIN Autor a ON pa.IdAutor = a.IdAutor
    JOIN TipoPublicacion tp ON p.IdTipoPublicacion = tp.IdTipoPublicacion
WHERE a.Nombre LIKE '%Gabriel%' AND a.Apellido LIKE '%García%';

--Estadísticas por tipo de publicación
SELECT 
    tp.NombreTipo,
    COUNT(p.IdPublicacion) AS CantidadPublicaciones,
    AVG(p.NumeroPaginas) AS PromedioPages
FROM TipoPublicacion tp
    LEFT JOIN Publicacion p ON tp.IdTipoPublicacion = p.IdTipoPublicacion
GROUP BY tp.IdTipoPublicacion, tp.NombreTipo
ORDER BY CantidadPublicaciones DESC;