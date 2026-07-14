USE [VUI_TransaccionesDB];
GO

/******************************************************************************
 Proyecto      : Dashboard Gobernanza
 Reporte       : Reporte 3
 Script        : Script 09 - Validación y conciliación de datos migrados
 Fecha         : 2026-07-14
 Autor         : Katiana Padilla

 Objetivo:
     Comparar los procesos finalizados extraídos mediante el Script 07 contra
     los registros cargados en dbo.VUI_Transaccion mediante el Script 08,
     verificando cantidades, fechas, relaciones, duplicados y consistencia de
     la información migrada.

 Descripción:
     Este script utiliza la tabla temporal #ProcesosFinalizados como fuente de
     conciliación, homologa nuevamente Bloque + Trámite con los catálogos de
     VUI_TransaccionesDB y compara cada registro contra VUI_Transaccion.

 Validaciones incluidas:
     • Total extraído vs. total encontrado en destino.
     • Cantidades por bloque y trámite.
     • Cantidades por año y mes de finalización.
     • Registros faltantes en destino.
     • Registros duplicados en destino.
     • Referencias repetidas dentro del mismo trámite.
     • Fechas de transacción diferentes entre origen y destino.
     • Estados y solicitantes asociados.
     • Trámites o bloques sin homologación.
     • Registros inactivos.
     • Resultado general de conciliación.

 Dependencias:
     • Script 07 - Extracción de procesos finalizados.
     • Script 08 - Importación masiva a VUI_Transaccion.
     • Catálogos activos en VUI_TransaccionesDB.
     • Tabla temporal #ProcesosFinalizados disponible en la misma sesión.

 Instrucciones:
     1. Ejecutar el Script 07 en la base AuraPortal_BPMS correspondiente.
     2. Ejecutar el Script 08 en VUI_TransaccionesDB.
     3. Sin cerrar la sesión de SSMS, ejecutar este Script 09.
     4. Revisar especialmente los resultados de diferencias y duplicados.
     5. La conciliación será satisfactoria cuando:
          - Registros faltantes = 0.
          - Registros con fecha diferente = 0.
          - Duplicados en destino = 0.
          - Diferencias por trámite, año y mes = 0.

 Observaciones:
     • Este script es únicamente de lectura.
     • No inserta, actualiza ni elimina información.
     • No reemplaza los datos dummy.
     • La sustitución de datos dummy se realizará mediante el Script 10.
******************************************************************************/

SET NOCOUNT ON;
SET XACT_ABORT ON;

/*============================================================================
  1. VALIDACIONES PREVIAS
============================================================================*/

IF DB_NAME() <> N'VUI_TransaccionesDB'
BEGIN
    THROW 50001,
          'El Script 09 debe ejecutarse en la base VUI_TransaccionesDB.',
          1;
END;

IF OBJECT_ID('tempdb..#ProcesosFinalizados') IS NULL
BEGIN
    THROW 50002,
          'No existe #ProcesosFinalizados. Ejecute primero el Script 07 en la misma sesión de SSMS.',
          1;
END;

IF OBJECT_ID('dbo.VUI_Bloque', 'U') IS NULL
   OR OBJECT_ID('dbo.VUI_Tramite', 'U') IS NULL
   OR OBJECT_ID('dbo.VUI_Transaccion', 'U') IS NULL
   OR OBJECT_ID('dbo.VUI_Estado', 'U') IS NULL
   OR OBJECT_ID('dbo.VUI_Solicitante', 'U') IS NULL
BEGIN
    THROW 50003,
          'Falta una o más tablas requeridas en VUI_TransaccionesDB.',
          1;
END;

/*============================================================================
  2. CONSTRUCCIÓN DE LA FUENTE HOMOLOGADA
============================================================================*/

IF OBJECT_ID('tempdb..#ConciliacionOrigen') IS NOT NULL
    DROP TABLE #ConciliacionOrigen;

CREATE TABLE #ConciliacionOrigen
(
    OrdenBloque        INT            NOT NULL,
    BloqueOrigen       NVARCHAR(150)  NOT NULL,
    OrdenTramite       INT            NOT NULL,
    TramiteOrigen      NVARCHAR(500)  NOT NULL,
    VUI_Tramite        BIGINT         NULL,
    IdProcesoOrigen    BIGINT         NOT NULL,
    Referencia         NVARCHAR(255)  NOT NULL,
    FechaFinalizacion  DATETIME       NOT NULL,
    Anio               INT            NOT NULL,
    Mes                INT            NOT NULL
);

INSERT INTO #ConciliacionOrigen
(
    OrdenBloque,
    BloqueOrigen,
    OrdenTramite,
    TramiteOrigen,
    VUI_Tramite,
    IdProcesoOrigen,
    Referencia,
    FechaFinalizacion,
    Anio,
    Mes
)
SELECT
    PF.OrdenBloque,
    PF.Bloque,
    PF.OrdenTramite,
    PF.Tramite,
    T.VUI_Tramite,
    PF.IdProcesoOrigen,
    LTRIM(RTRIM(PF.Referencia)),
    PF.FechaFinalizacion,
    YEAR(PF.FechaFinalizacion),
    MONTH(PF.FechaFinalizacion)
FROM #ProcesosFinalizados PF
LEFT JOIN dbo.VUI_Bloque B
    ON B.Nombre = PF.Bloque
   AND B.Activo = 1
LEFT JOIN dbo.VUI_Tramite T
    ON T.VUI_Bloque = B.VUI_Bloque
   AND T.Nombre = PF.Tramite
   AND T.Activo = 1;

/*============================================================================
  RESULTADO 1: BLOQUES Y TRÁMITES SIN HOMOLOGAR
  Debe quedar vacío.
============================================================================*/

SELECT DISTINCT
    C.OrdenBloque,
    C.BloqueOrigen,
    C.OrdenTramite,
    C.TramiteOrigen,
    N'No existe coincidencia activa en VUI_Bloque/VUI_Tramite' AS Motivo
FROM #ConciliacionOrigen C
WHERE C.VUI_Tramite IS NULL
ORDER BY C.OrdenBloque, C.OrdenTramite;

/*============================================================================
  3. CONJUNTO DE DESTINO RELACIONADO CON LA EXTRACCIÓN
============================================================================*/

IF OBJECT_ID('tempdb..#ConciliacionDestino') IS NOT NULL
    DROP TABLE #ConciliacionDestino;

CREATE TABLE #ConciliacionDestino
(
    VUI_Transaccion    BIGINT         NOT NULL,
    VUI_Tramite        BIGINT         NOT NULL,
    VUI_Estado         BIGINT         NOT NULL,
    VUI_Solicitante    BIGINT         NULL,
    Referencia         NVARCHAR(255)  NOT NULL,
    FechaTransaccion   DATETIME       NOT NULL,
    Activo             BIT            NOT NULL
);

INSERT INTO #ConciliacionDestino
(
    VUI_Transaccion,
    VUI_Tramite,
    VUI_Estado,
    VUI_Solicitante,
    Referencia,
    FechaTransaccion,
    Activo
)
SELECT
    TX.VUI_Transaccion,
    TX.VUI_Tramite,
    TX.VUI_Estado,
    TX.VUI_Solicitante,
    LTRIM(RTRIM(TX.Referencia)),
    TX.FechaTransaccion,
    TX.Activo
FROM dbo.VUI_Transaccion TX
WHERE EXISTS
(
    SELECT 1
    FROM #ConciliacionOrigen O
    WHERE O.VUI_Tramite = TX.VUI_Tramite
      AND O.Referencia = LTRIM(RTRIM(TX.Referencia))
);

/*============================================================================
  RESULTADO 2: RESUMEN GENERAL
============================================================================*/

DECLARE @TotalOrigen               INT;
DECLARE @TotalHomologado           INT;
DECLARE @TotalCoincidenteExacto    INT;
DECLARE @TotalFaltante             INT;
DECLARE @TotalFechaDiferente       INT;
DECLARE @TotalDuplicadoDestino     INT;
DECLARE @TotalInactivo             INT;

SELECT @TotalOrigen = COUNT(*)
FROM #ConciliacionOrigen;

SELECT @TotalHomologado = COUNT(*)
FROM #ConciliacionOrigen
WHERE VUI_Tramite IS NOT NULL;

SELECT @TotalCoincidenteExacto = COUNT(*)
FROM #ConciliacionOrigen O
WHERE EXISTS
(
    SELECT 1
    FROM dbo.VUI_Transaccion TX
    WHERE TX.VUI_Tramite = O.VUI_Tramite
      AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
      AND TX.FechaTransaccion = O.FechaFinalizacion
      AND TX.Activo = 1
);

SELECT @TotalFaltante = COUNT(*)
FROM #ConciliacionOrigen O
WHERE O.VUI_Tramite IS NOT NULL
  AND NOT EXISTS
(
    SELECT 1
    FROM dbo.VUI_Transaccion TX
    WHERE TX.VUI_Tramite = O.VUI_Tramite
      AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
      AND TX.FechaTransaccion = O.FechaFinalizacion
      AND TX.Activo = 1
);

SELECT @TotalFechaDiferente = COUNT(*)
FROM #ConciliacionOrigen O
WHERE O.VUI_Tramite IS NOT NULL
  AND EXISTS
(
    SELECT 1
    FROM dbo.VUI_Transaccion TX
    WHERE TX.VUI_Tramite = O.VUI_Tramite
      AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
      AND TX.FechaTransaccion <> O.FechaFinalizacion
);

SELECT @TotalDuplicadoDestino = COUNT(*)
FROM
(
    SELECT
        TX.VUI_Tramite,
        LTRIM(RTRIM(TX.Referencia)) AS Referencia,
        TX.FechaTransaccion
    FROM dbo.VUI_Transaccion TX
    INNER JOIN
    (
        SELECT DISTINCT
            VUI_Tramite,
            Referencia
        FROM #ConciliacionOrigen
        WHERE VUI_Tramite IS NOT NULL
    ) O
        ON O.VUI_Tramite = TX.VUI_Tramite
       AND O.Referencia = LTRIM(RTRIM(TX.Referencia))
    GROUP BY
        TX.VUI_Tramite,
        LTRIM(RTRIM(TX.Referencia)),
        TX.FechaTransaccion
    HAVING COUNT(*) > 1
) D;

SELECT @TotalInactivo = COUNT(*)
FROM #ConciliacionOrigen O
WHERE EXISTS
(
    SELECT 1
    FROM dbo.VUI_Transaccion TX
    WHERE TX.VUI_Tramite = O.VUI_Tramite
      AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
      AND TX.FechaTransaccion = O.FechaFinalizacion
      AND TX.Activo = 0
);

SELECT
    @TotalOrigen AS TotalExtraido,
    @TotalHomologado AS TotalHomologado,
    @TotalCoincidenteExacto AS TotalCoincidenteExacto,
    @TotalFaltante AS TotalFaltante,
    @TotalFechaDiferente AS TotalFechaDiferente,
    @TotalDuplicadoDestino AS GruposDuplicadosDestino,
    @TotalInactivo AS TotalCoincidenteInactivo,
    CASE
        WHEN @TotalOrigen = @TotalHomologado
         AND @TotalOrigen = @TotalCoincidenteExacto
         AND @TotalFaltante = 0
         AND @TotalFechaDiferente = 0
         AND @TotalDuplicadoDestino = 0
         AND @TotalInactivo = 0
        THEN N'CONCILIACIÓN SATISFACTORIA'
        ELSE N'CONCILIACIÓN CON DIFERENCIAS'
    END AS ResultadoGeneral;

/*============================================================================
  RESULTADO 3: CONCILIACIÓN POR BLOQUE Y TRÁMITE
============================================================================*/

;WITH Origen AS
(
    SELECT
        OrdenBloque,
        BloqueOrigen,
        OrdenTramite,
        TramiteOrigen,
        VUI_Tramite,
        COUNT(*) AS CantidadOrigen
    FROM #ConciliacionOrigen
    GROUP BY
        OrdenBloque,
        BloqueOrigen,
        OrdenTramite,
        TramiteOrigen,
        VUI_Tramite
),
Destino AS
(
    SELECT
        O.OrdenBloque,
        O.BloqueOrigen,
        O.OrdenTramite,
        O.TramiteOrigen,
        O.VUI_Tramite,
        COUNT(*) AS CantidadDestino
    FROM #ConciliacionOrigen O
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.VUI_Transaccion TX
        WHERE TX.VUI_Tramite = O.VUI_Tramite
          AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
          AND TX.FechaTransaccion = O.FechaFinalizacion
          AND TX.Activo = 1
    )
    GROUP BY
        O.OrdenBloque,
        O.BloqueOrigen,
        O.OrdenTramite,
        O.TramiteOrigen,
        O.VUI_Tramite
)
SELECT
    O.OrdenBloque,
    O.BloqueOrigen AS Bloque,
    O.OrdenTramite,
    O.TramiteOrigen AS Tramite,
    O.CantidadOrigen,
    ISNULL(D.CantidadDestino, 0) AS CantidadDestino,
    O.CantidadOrigen - ISNULL(D.CantidadDestino, 0) AS Diferencia,
    CASE
        WHEN O.CantidadOrigen = ISNULL(D.CantidadDestino, 0)
        THEN N'OK'
        ELSE N'REVISAR'
    END AS EstadoConciliacion
FROM Origen O
LEFT JOIN Destino D
    ON D.OrdenBloque = O.OrdenBloque
   AND D.OrdenTramite = O.OrdenTramite
   AND ISNULL(D.VUI_Tramite, -1) = ISNULL(O.VUI_Tramite, -1)
ORDER BY O.OrdenBloque, O.OrdenTramite;

/*============================================================================
  RESULTADO 4: CONCILIACIÓN POR AÑO Y MES
============================================================================*/

;WITH OrigenMes AS
(
    SELECT
        OrdenBloque,
        BloqueOrigen,
        OrdenTramite,
        TramiteOrigen,
        VUI_Tramite,
        Anio,
        Mes,
        COUNT(*) AS CantidadOrigen
    FROM #ConciliacionOrigen
    GROUP BY
        OrdenBloque,
        BloqueOrigen,
        OrdenTramite,
        TramiteOrigen,
        VUI_Tramite,
        Anio,
        Mes
),
DestinoMes AS
(
    SELECT
        O.OrdenBloque,
        O.BloqueOrigen,
        O.OrdenTramite,
        O.TramiteOrigen,
        O.VUI_Tramite,
        O.Anio,
        O.Mes,
        COUNT(*) AS CantidadDestino
    FROM #ConciliacionOrigen O
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.VUI_Transaccion TX
        WHERE TX.VUI_Tramite = O.VUI_Tramite
          AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
          AND TX.FechaTransaccion = O.FechaFinalizacion
          AND TX.Activo = 1
    )
    GROUP BY
        O.OrdenBloque,
        O.BloqueOrigen,
        O.OrdenTramite,
        O.TramiteOrigen,
        O.VUI_Tramite,
        O.Anio,
        O.Mes
)
SELECT
    O.OrdenBloque,
    O.BloqueOrigen AS Bloque,
    O.OrdenTramite,
    O.TramiteOrigen AS Tramite,
    O.Anio,
    O.Mes,
    O.CantidadOrigen,
    ISNULL(D.CantidadDestino, 0) AS CantidadDestino,
    O.CantidadOrigen - ISNULL(D.CantidadDestino, 0) AS Diferencia,
    CASE
        WHEN O.CantidadOrigen = ISNULL(D.CantidadDestino, 0)
        THEN N'OK'
        ELSE N'REVISAR'
    END AS EstadoConciliacion
FROM OrigenMes O
LEFT JOIN DestinoMes D
    ON D.OrdenBloque = O.OrdenBloque
   AND D.OrdenTramite = O.OrdenTramite
   AND ISNULL(D.VUI_Tramite, -1) = ISNULL(O.VUI_Tramite, -1)
   AND D.Anio = O.Anio
   AND D.Mes = O.Mes
ORDER BY
    O.OrdenBloque,
    O.OrdenTramite,
    O.Anio,
    O.Mes;

/*============================================================================
  RESULTADO 5: REGISTROS FALTANTES EN DESTINO
  Debe quedar vacío.
============================================================================*/

SELECT
    O.OrdenBloque,
    O.BloqueOrigen AS Bloque,
    O.OrdenTramite,
    O.TramiteOrigen AS Tramite,
    O.IdProcesoOrigen,
    O.Referencia,
    O.FechaFinalizacion
FROM #ConciliacionOrigen O
WHERE O.VUI_Tramite IS NOT NULL
  AND NOT EXISTS
(
    SELECT 1
    FROM dbo.VUI_Transaccion TX
    WHERE TX.VUI_Tramite = O.VUI_Tramite
      AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
      AND TX.FechaTransaccion = O.FechaFinalizacion
      AND TX.Activo = 1
)
ORDER BY
    O.OrdenBloque,
    O.OrdenTramite,
    O.FechaFinalizacion,
    O.IdProcesoOrigen;

/*============================================================================
  RESULTADO 6: REFERENCIAS CON FECHA DIFERENTE
  Debe quedar vacío.
============================================================================*/

SELECT
    O.OrdenBloque,
    O.BloqueOrigen AS Bloque,
    O.OrdenTramite,
    O.TramiteOrigen AS Tramite,
    O.IdProcesoOrigen,
    O.Referencia,
    O.FechaFinalizacion AS FechaOrigen,
    TX.FechaTransaccion AS FechaDestino,
    DATEDIFF(SECOND, O.FechaFinalizacion, TX.FechaTransaccion) AS DiferenciaSegundos
FROM #ConciliacionOrigen O
INNER JOIN dbo.VUI_Transaccion TX
    ON TX.VUI_Tramite = O.VUI_Tramite
   AND LTRIM(RTRIM(TX.Referencia)) = O.Referencia
WHERE TX.FechaTransaccion <> O.FechaFinalizacion
ORDER BY
    O.OrdenBloque,
    O.OrdenTramite,
    O.Referencia;

/*============================================================================
  RESULTADO 7: DUPLICADOS EN DESTINO
  Debe quedar vacío.
============================================================================*/

SELECT
    TX.VUI_Tramite,
    T.Nombre AS Tramite,
    LTRIM(RTRIM(TX.Referencia)) AS Referencia,
    TX.FechaTransaccion,
    COUNT(*) AS CantidadRepeticiones
FROM dbo.VUI_Transaccion TX
INNER JOIN dbo.VUI_Tramite T
    ON T.VUI_Tramite = TX.VUI_Tramite
WHERE EXISTS
(
    SELECT 1
    FROM #ConciliacionOrigen O
    WHERE O.VUI_Tramite = TX.VUI_Tramite
      AND O.Referencia = LTRIM(RTRIM(TX.Referencia))
)
GROUP BY
    TX.VUI_Tramite,
    T.Nombre,
    LTRIM(RTRIM(TX.Referencia)),
    TX.FechaTransaccion
HAVING COUNT(*) > 1
ORDER BY
    T.Nombre,
    Referencia,
    TX.FechaTransaccion;

/*============================================================================
  RESULTADO 8: ESTADOS Y SOLICITANTES ASOCIADOS
============================================================================*/

SELECT
    B.Nombre AS Bloque,
    T.Nombre AS Tramite,
    E.Nombre AS Estado,
    S.Nombre AS Solicitante,
    TX.Activo,
    COUNT(*) AS Cantidad
FROM dbo.VUI_Transaccion TX
INNER JOIN dbo.VUI_Tramite T
    ON T.VUI_Tramite = TX.VUI_Tramite
INNER JOIN dbo.VUI_Bloque B
    ON B.VUI_Bloque = T.VUI_Bloque
INNER JOIN dbo.VUI_Estado E
    ON E.VUI_Estado = TX.VUI_Estado
LEFT JOIN dbo.VUI_Solicitante S
    ON S.VUI_Solicitante = TX.VUI_Solicitante
WHERE EXISTS
(
    SELECT 1
    FROM #ConciliacionOrigen O
    WHERE O.VUI_Tramite = TX.VUI_Tramite
      AND O.Referencia = LTRIM(RTRIM(TX.Referencia))
      AND O.FechaFinalizacion = TX.FechaTransaccion
)
GROUP BY
    B.Nombre,
    T.Nombre,
    E.Nombre,
    S.Nombre,
    TX.Activo
ORDER BY
    B.Nombre,
    T.Nombre,
    E.Nombre,
    S.Nombre;

/*============================================================================
  RESULTADO 9: REGISTROS CONCILIADOS PERO INACTIVOS
  Debe quedar vacío.
============================================================================*/

SELECT
    B.Nombre AS Bloque,
    T.Nombre AS Tramite,
    TX.VUI_Transaccion,
    TX.Referencia,
    TX.FechaTransaccion,
    TX.Activo
FROM dbo.VUI_Transaccion TX
INNER JOIN dbo.VUI_Tramite T
    ON T.VUI_Tramite = TX.VUI_Tramite
INNER JOIN dbo.VUI_Bloque B
    ON B.VUI_Bloque = T.VUI_Bloque
WHERE TX.Activo = 0
  AND EXISTS
(
    SELECT 1
    FROM #ConciliacionOrigen O
    WHERE O.VUI_Tramite = TX.VUI_Tramite
      AND O.Referencia = LTRIM(RTRIM(TX.Referencia))
      AND O.FechaFinalizacion = TX.FechaTransaccion
)
ORDER BY
    B.Nombre,
    T.Nombre,
    TX.FechaTransaccion;

/*============================================================================
  RESULTADO 10: CONCLUSIÓN FINAL
============================================================================*/

SELECT
    CASE
        WHEN @TotalOrigen = @TotalHomologado
         AND @TotalOrigen = @TotalCoincidenteExacto
         AND @TotalFaltante = 0
         AND @TotalFechaDiferente = 0
         AND @TotalDuplicadoDestino = 0
         AND @TotalInactivo = 0
        THEN N'APROBADO: La migración está conciliada y no presenta diferencias.'
        ELSE N'REVISAR: La migración presenta diferencias. Consulte los resultados anteriores.'
    END AS Conclusion,
    @TotalOrigen AS TotalOrigen,
    @TotalCoincidenteExacto AS TotalDestinoConciliado,
    @TotalFaltante AS Faltantes,
    @TotalFechaDiferente AS FechasDiferentes,
    @TotalDuplicadoDestino AS Duplicados,
    @TotalInactivo AS Inactivos;
GO
