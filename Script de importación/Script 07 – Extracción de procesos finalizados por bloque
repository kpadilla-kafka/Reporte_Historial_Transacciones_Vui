USE [AuraPortal_BPMS_DES];
GO

/******************************************************************************
 Proyecto      : Dashboard Gobernanza
 Reporte       : Reporte 3
 Script        : Script 07 - Extracción de procesos finalizados
 Fecha         : 2026-07-14
 Autor         : Katiana Padilla

 Descripción:
     Extrae los procesos finalizados desde la base de datos origen y los
     consolida en una tabla temporal para su revisión y conciliación previa
     a la importación en VUI_TransaccionesDB.

 Reglas principales:
     - Solo se consideran procesos terminados: IdEstado = 1.
     - La fecha oficial de la transacción es FechaTerminar.
     - Se excluyen fechas nulas o inválidas (1900-01-01).
     - Los filtros particulares por panel se mantienen según el Reporte 1.
     - Este script NO inserta información en VUI_TransaccionesDB.

 Ambientes:
     - Ejecutar y probar inicialmente en AuraPortal_BPMS_DES.
     - Validar cantidades oficiales en AuraPortal_BPMS_PROD.

El mismo patrón servirá para los demás bloques. Lo único que cambia será el listado de trámites (IdClaseProceso).
******************************************************************************/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @FechaInicio DATE = NULL;
DECLARE @FechaFin    DATE = NULL;

/* Validación de parámetros */
IF @FechaInicio IS NOT NULL
   AND @FechaFin IS NOT NULL
   AND @FechaInicio > @FechaFin
BEGIN
    THROW 50001, 'La fecha inicial no puede ser mayor que la fecha final.', 1;
END;

IF OBJECT_ID('tempdb..#ProcesosFinalizados') IS NOT NULL
    DROP TABLE #ProcesosFinalizados;

CREATE TABLE #ProcesosFinalizados
(
    OrdenBloque        INT            NOT NULL,
    Bloque              NVARCHAR(150)  NOT NULL,
    OrdenTramite        INT            NOT NULL,
    IdClaseProceso      INT            NOT NULL,
    Tramite             NVARCHAR(500)  NOT NULL,
    IdProcesoOrigen     BIGINT         NOT NULL,
    Referencia          NVARCHAR(250)  NULL,
    IdEstadoOrigen      INT            NOT NULL,
    FechaInicio         DATETIME       NULL,
    FechaFinalizacion   DATETIME       NOT NULL,
    Anio                INT            NOT NULL,
    Mes                 INT            NOT NULL
);

/*============================================================================
  BLOQUE 1: Trámites previos a Apertura de Empresa
============================================================================*/

/* 1. Calderas (Versión 1) */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    1,
    P.IdClaseProceso,
    N'Calderas (Versión 1)',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
WHERE P.IdClaseProceso = 45
  AND P.IdEstado = 1
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 2. Calderas Operación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    2,
    P.IdClaseProceso,
    N'Calderas Operación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_154 AS P154
    ON P154._ElementID = P.ID
WHERE P.IdClaseProceso = 154
  AND P.IdEstado = 1
  AND P154.[3_Selección de trámite caldera] = 2216
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 3. Calderas Instalación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    3,
    P.IdClaseProceso,
    N'Calderas Instalación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_154 AS P154
    ON P154._ElementID = P.ID
WHERE P.IdClaseProceso = 154
  AND P.IdEstado = 1
  AND P154.[3_Selección de trámite caldera] = 2215
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 4. Calderas Inspección Anual */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    4,
    P.IdClaseProceso,
    N'Calderas Inspección Anual',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_152 AS P152
    ON P152._ElementID = P.ID
WHERE P.IdClaseProceso = 152
  AND P.IdEstado = 1
  AND P152.[3_Tipo de trámite - Módulos calderas] = 11513
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 5. Calderas Renovación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    5,
    P.IdClaseProceso,
    N'Calderas Renovación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_152 AS P152
    ON P152._ElementID = P.ID
WHERE P.IdClaseProceso = 152
  AND P.IdEstado = 1
  AND P152.[3_Tipo de trámite - Módulos calderas] = 11510
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 6. Calderas Modificación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    6,
    P.IdClaseProceso,
    N'Calderas Modificación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_152 AS P152
    ON P152._ElementID = P.ID
WHERE P.IdClaseProceso = 152
  AND P.IdEstado = 1
  AND P152.[3_Tipo de trámite - Módulos calderas] = 12311
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 7. Calderas Cancelación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    7,
    P.IdClaseProceso,
    N'Calderas Cancelación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_152 AS P152
    ON P152._ElementID = P.ID
WHERE P.IdClaseProceso = 152
  AND P.IdEstado = 1
  AND P152.[3_Tipo de trámite - Módulos calderas] = 11512
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 8. Sistema de Tratamiento de Aguas Residuales */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    8,
    P.IdClaseProceso,
    N'Sistema de Tratamiento de Aguas Residuales',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
WHERE P.IdClaseProceso = 38
  AND P.IdEstado = 1
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 9. STAR Renovación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    9,
    P.IdClaseProceso,
    N'Sistema de Tratamiento de Aguas Residuales Renovación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_176 AS P176
    ON P176._ElementID = P.ID
WHERE P.IdClaseProceso = 176
  AND P.IdEstado = 1
  AND P176.[3_Tipo de trámite STAR] = 12126
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 10. STAR Modificación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    10,
    P.IdClaseProceso,
    N'Sistema de Tratamiento de Aguas Residuales Modificación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_176 AS P176
    ON P176._ElementID = P.ID
WHERE P.IdClaseProceso = 176
  AND P.IdEstado = 1
  AND P176.[3_Tipo de trámite STAR] = 12125
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 11. Tanques de Autoconsumo */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    11,
    P.IdClaseProceso,
    N'Tanques de Autoconsumo',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
WHERE P.IdClaseProceso = 44
  AND P.IdEstado = 1
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 12. Tanques de Autoconsumo Renovación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    12,
    P.IdClaseProceso,
    N'Tanques de Autoconsumo Renovación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_192 AS P192
    ON P192._ElementID = P.ID
WHERE P.IdClaseProceso = 192
  AND P.IdEstado = 1
  AND P192.[3_Tipo de trámite Tanques] = 12788
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 13. Tanques de Autoconsumo Modificación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    13,
    P.IdClaseProceso,
    N'Tanques de Autoconsumo Modificación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_192 AS P192
    ON P192._ElementID = P.ID
WHERE P.IdClaseProceso = 192
  AND P.IdEstado = 1
  AND P192.[3_Tipo de trámite Tanques] = 12787
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/* 14. Tanques de Autoconsumo Cancelación */
INSERT INTO #ProcesosFinalizados
SELECT
    1,
    N'Trámites previos a Apertura de Empresa',
    14,
    P.IdClaseProceso,
    N'Tanques de Autoconsumo Cancelación',
    P.ID,
    P.Referencia,
    P.IdEstado,
    P.FechaInicio,
    P.FechaTerminar,
    YEAR(P.FechaTerminar),
    MONTH(P.FechaTerminar)
FROM dbo.AP__BPM_Procesos AS P
INNER JOIN dbo.Panel_192 AS P192
    ON P192._ElementID = P.ID
WHERE P.IdClaseProceso = 192
  AND P.IdEstado = 1
  AND P192.[3_Tipo de trámite Tanques] = 12789
  AND P.FechaTerminar IS NOT NULL
  AND P.FechaTerminar > '19000101'
  AND (@FechaInicio IS NULL OR P.FechaTerminar >= @FechaInicio)
  AND (@FechaFin IS NULL OR P.FechaTerminar < DATEADD(DAY, 1, @FechaFin));

/*============================================================================
  VALIDACIONES
============================================================================*/

/* Resumen por trámite */
SELECT
    OrdenBloque,
    Bloque,
    OrdenTramite,
    IdClaseProceso,
    Tramite,
    COUNT(*) AS CantidadProcesosFinalizados,
    MIN(FechaFinalizacion) AS PrimeraFinalizacion,
    MAX(FechaFinalizacion) AS UltimaFinalizacion
FROM #ProcesosFinalizados
GROUP BY
    OrdenBloque,
    Bloque,
    OrdenTramite,
    IdClaseProceso,
    Tramite
ORDER BY
    OrdenBloque,
    OrdenTramite;

/* Detalle extraído */
SELECT
    OrdenBloque,
    Bloque,
    OrdenTramite,
    IdClaseProceso,
    Tramite,
    IdProcesoOrigen,
    Referencia,
    IdEstadoOrigen,
    FechaInicio,
    FechaFinalizacion,
    Anio,
    Mes
FROM #ProcesosFinalizados
ORDER BY
    OrdenBloque,
    OrdenTramite,
    FechaFinalizacion,
    IdProcesoOrigen;

/* Control de duplicados dentro de la extracción */
SELECT
    IdProcesoOrigen,
    Tramite,
    COUNT(*) AS Cantidad
FROM #ProcesosFinalizados
GROUP BY
    IdProcesoOrigen,
    Tramite
HAVING COUNT(*) > 1;
GO
