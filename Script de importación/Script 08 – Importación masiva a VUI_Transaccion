USE [VUI_TransaccionesDB];
GO

/******************************************************************************
 Proyecto      : Dashboard Gobernanza
 Reporte       : Reporte 3
 Script        : Script 08 - Importación masiva a VUI_Transaccion
 Fecha         : 2026-07-14
 Autor         : Katiana Padilla

 Descripción:
     Importa en dbo.VUI_Transaccion los procesos finalizados previamente
     extraídos mediante el Script 07 y almacenados en la tabla temporal local
     #ProcesosFinalizados.

 Características:
     - Valida la existencia de tablas y columnas requeridas.
     - Homologa Bloque + Trámite contra los catálogos de la nueva base.
     - Valida el estado de destino.
     - Permite VUI_Solicitante en NULL cuando el origen no lo proporciona.
     - Evita duplicados usando:
           Referencia + VUI_Tramite + FechaTransaccion
     - Es idempotente: puede ejecutarse nuevamente sin duplicar registros.
     - Ejecuta la carga dentro de una transacción.
     - Realiza ROLLBACK automático ante errores.
     - Incluye modo simulación antes del COMMIT definitivo.

 IMPORTANTE:
     1. Ejecutar primero el Script 07 en la MISMA sesión de SSMS.
        La tabla temporal local #ProcesosFinalizados debe seguir disponible.
     2. Configurar @NombreEstadoDestino según la regla funcional confirmada.
        IdEstadoOrigen = 1 significa "Terminado", pero no determina por sí solo
        si el resultado final fue Aprobado, Rechazado o Archivado.
     3. La primera ejecución debe realizarse con @ConfirmarCarga = 0.
******************************************************************************/

SET NOCOUNT ON;
SET XACT_ABORT ON;

/*============================================================================
  1. PARÁMETROS DE EJECUCIÓN
============================================================================*/

DECLARE @NombreEstadoDestino NVARCHAR(100) = NULL;
/*
 Ejemplos válidos según el catálogo:
     N'Aprobado'
     N'Rechazado'
     N'Archivado'

 No se asigna un valor automáticamente porque "Terminado" no equivale
 necesariamente a "Aprobado".
*/

DECLARE @NombreSolicitanteDestino NVARCHAR(100) = NULL;
/*
 Puede mantenerse en NULL cuando el Script 07 no proporciona el tipo de
 solicitante. Si se indica un nombre, debe existir y estar activo en
 dbo.VUI_Solicitante.
*/

DECLARE @ConfirmarCarga BIT = 0;
/*
 0 = Simulación segura. Ejecuta todas las validaciones y el INSERT,
     muestra resultados y finalmente realiza ROLLBACK.
 1 = Carga definitiva. Si todas las validaciones son correctas, hace COMMIT.
*/

/*============================================================================
  2. VARIABLES DE CONTROL
============================================================================*/

DECLARE @VUI_EstadoDestino      BIGINT = NULL;
DECLARE @VUI_SolicitanteDestino BIGINT = NULL;
DECLARE @TotalOrigen            INT = 0;
DECLARE @TotalPreparado         INT = 0;
DECLARE @TotalYaExistente       INT = 0;
DECLARE @TotalInsertado         INT = 0;
DECLARE @TotalDestinoPosterior  INT = 0;

/*============================================================================
  3. VALIDACIONES PREVIAS DE ESTRUCTURA
============================================================================*/

IF DB_NAME() <> N'VUI_TransaccionesDB'
BEGIN
    THROW 50001,
          'El Script 08 debe ejecutarse en la base VUI_TransaccionesDB.',
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
   OR OBJECT_ID('dbo.VUI_Estado', 'U') IS NULL
   OR OBJECT_ID('dbo.VUI_Solicitante', 'U') IS NULL
   OR OBJECT_ID('dbo.VUI_Transaccion', 'U') IS NULL
BEGIN
    THROW 50003,
          'Falta una o más tablas requeridas en VUI_TransaccionesDB.',
          1;
END;

IF COL_LENGTH('tempdb..#ProcesosFinalizados', 'Bloque') IS NULL
   OR COL_LENGTH('tempdb..#ProcesosFinalizados', 'Tramite') IS NULL
   OR COL_LENGTH('tempdb..#ProcesosFinalizados', 'IdProcesoOrigen') IS NULL
   OR COL_LENGTH('tempdb..#ProcesosFinalizados', 'Referencia') IS NULL
   OR COL_LENGTH('tempdb..#ProcesosFinalizados', 'IdEstadoOrigen') IS NULL
   OR COL_LENGTH('tempdb..#ProcesosFinalizados', 'FechaFinalizacion') IS NULL
BEGIN
    THROW 50004,
          'La estructura de #ProcesosFinalizados no coincide con la esperada por el Script 08.',
          1;
END;

/*============================================================================
  4. VALIDACIÓN DEL ESTADO Y SOLICITANTE DE DESTINO
============================================================================*/

IF NULLIF(LTRIM(RTRIM(@NombreEstadoDestino)), N'') IS NULL
BEGIN
    THROW 50005,
          'Debe configurar @NombreEstadoDestino antes de ejecutar la importación.',
          1;
END;

IF (
    SELECT COUNT(*)
    FROM dbo.VUI_Estado
    WHERE Nombre = @NombreEstadoDestino
      AND Activo = 1
   ) <> 1
BEGIN
    THROW 50006,
          'El estado de destino no existe, está inactivo o está duplicado en VUI_Estado.',
          1;
END;

SELECT @VUI_EstadoDestino = VUI_Estado
FROM dbo.VUI_Estado
WHERE Nombre = @NombreEstadoDestino
  AND Activo = 1;

IF NULLIF(LTRIM(RTRIM(@NombreSolicitanteDestino)), N'') IS NOT NULL
BEGIN
    IF (
        SELECT COUNT(*)
        FROM dbo.VUI_Solicitante
        WHERE Nombre = @NombreSolicitanteDestino
          AND Activo = 1
       ) <> 1
    BEGIN
        THROW 50007,
              'El solicitante de destino no existe, está inactivo o está duplicado en VUI_Solicitante.',
              1;
    END;

    SELECT @VUI_SolicitanteDestino = VUI_Solicitante
    FROM dbo.VUI_Solicitante
    WHERE Nombre = @NombreSolicitanteDestino
      AND Activo = 1;
END;

/*============================================================================
  5. VALIDACIÓN DE CALIDAD DE LA EXTRACCIÓN
============================================================================*/

SELECT @TotalOrigen = COUNT(*)
FROM #ProcesosFinalizados;

IF @TotalOrigen = 0
BEGIN
    THROW 50008,
          'La tabla #ProcesosFinalizados no contiene registros para importar.',
          1;
END;

IF EXISTS
(
    SELECT 1
    FROM #ProcesosFinalizados
    WHERE IdEstadoOrigen <> 1
)
BEGIN
    THROW 50009,
          'La extracción contiene procesos cuyo IdEstadoOrigen es diferente de 1.',
          1;
END;

IF EXISTS
(
    SELECT 1
    FROM #ProcesosFinalizados
    WHERE FechaFinalizacion IS NULL
       OR FechaFinalizacion <= '19000101'
)
BEGIN
    THROW 50010,
          'La extracción contiene fechas de finalización nulas o inválidas.',
          1;
END;

IF EXISTS
(
    SELECT 1
    FROM #ProcesosFinalizados
    WHERE NULLIF(LTRIM(RTRIM(Referencia)), N'') IS NULL
)
BEGIN
    THROW 50011,
          'La extracción contiene referencias nulas o vacías.',
          1;
END;

IF EXISTS
(
    SELECT
        Bloque,
        Tramite,
        IdProcesoOrigen
    FROM #ProcesosFinalizados
    GROUP BY
        Bloque,
        Tramite,
        IdProcesoOrigen
    HAVING COUNT(*) > 1
)
BEGIN
    THROW 50012,
          'La extracción contiene procesos duplicados dentro del mismo trámite.',
          1;
END;

/*============================================================================
  6. HOMOLOGACIÓN DE BLOQUES Y TRÁMITES
============================================================================*/

IF OBJECT_ID('tempdb..#CargaHomologada') IS NOT NULL
    DROP TABLE #CargaHomologada;

CREATE TABLE #CargaHomologada
(
    VUI_Tramite       BIGINT        NOT NULL,
    VUI_Estado        BIGINT        NOT NULL,
    VUI_Solicitante   BIGINT        NULL,
    Referencia        NVARCHAR(255) NOT NULL,
    FechaTransaccion  DATETIME      NOT NULL,
    IdProcesoOrigen   BIGINT        NOT NULL,
    BloqueOrigen      NVARCHAR(150) NOT NULL,
    TramiteOrigen     NVARCHAR(500) NOT NULL
);

/* Detener la carga si algún bloque o trámite no tiene coincidencia exacta. */
IF EXISTS
(
    SELECT 1
    FROM #ProcesosFinalizados PF
    LEFT JOIN dbo.VUI_Bloque B
        ON B.Nombre = PF.Bloque
       AND B.Activo = 1
    LEFT JOIN dbo.VUI_Tramite T
        ON T.VUI_Bloque = B.VUI_Bloque
       AND T.Nombre = PF.Tramite
       AND T.Activo = 1
    WHERE B.VUI_Bloque IS NULL
       OR T.VUI_Tramite IS NULL
)
BEGIN
    SELECT DISTINCT
        PF.Bloque,
        PF.Tramite,
        CASE
            WHEN B.VUI_Bloque IS NULL THEN N'Bloque no encontrado o inactivo'
            WHEN T.VUI_Tramite IS NULL THEN N'Trámite no encontrado o inactivo'
        END AS Motivo
    FROM #ProcesosFinalizados PF
    LEFT JOIN dbo.VUI_Bloque B
        ON B.Nombre = PF.Bloque
       AND B.Activo = 1
    LEFT JOIN dbo.VUI_Tramite T
        ON T.VUI_Bloque = B.VUI_Bloque
       AND T.Nombre = PF.Tramite
       AND T.Activo = 1
    WHERE B.VUI_Bloque IS NULL
       OR T.VUI_Tramite IS NULL
    ORDER BY PF.Bloque, PF.Tramite;

    THROW 50013,
          'Existen bloques o trámites sin homologar. Revise el resultado anterior.',
          1;
END;

/* Evitar multiplicación de filas por catálogos duplicados. */
IF EXISTS
(
    SELECT
        PF.Bloque,
        PF.Tramite
    FROM #ProcesosFinalizados PF
    INNER JOIN dbo.VUI_Bloque B
        ON B.Nombre = PF.Bloque
       AND B.Activo = 1
    INNER JOIN dbo.VUI_Tramite T
        ON T.VUI_Bloque = B.VUI_Bloque
       AND T.Nombre = PF.Tramite
       AND T.Activo = 1
    GROUP BY
        PF.Bloque,
        PF.Tramite
    HAVING COUNT(DISTINCT T.VUI_Tramite) <> 1
)
BEGIN
    THROW 50014,
          'Existe una homologación ambigua por nombres duplicados en los catálogos.',
          1;
END;

INSERT INTO #CargaHomologada
(
    VUI_Tramite,
    VUI_Estado,
    VUI_Solicitante,
    Referencia,
    FechaTransaccion,
    IdProcesoOrigen,
    BloqueOrigen,
    TramiteOrigen
)
SELECT
    T.VUI_Tramite,
    @VUI_EstadoDestino,
    @VUI_SolicitanteDestino,
    LTRIM(RTRIM(PF.Referencia)),
    PF.FechaFinalizacion,
    PF.IdProcesoOrigen,
    PF.Bloque,
    PF.Tramite
FROM #ProcesosFinalizados PF
INNER JOIN dbo.VUI_Bloque B
    ON B.Nombre = PF.Bloque
   AND B.Activo = 1
INNER JOIN dbo.VUI_Tramite T
    ON T.VUI_Bloque = B.VUI_Bloque
   AND T.Nombre = PF.Tramite
   AND T.Activo = 1;

SET @TotalPreparado = @@ROWCOUNT;

IF @TotalPreparado <> @TotalOrigen
BEGIN
    THROW 50015,
          'La cantidad homologada no coincide con la cantidad extraída.',
          1;
END;

/*============================================================================
  7. CLASIFICACIÓN PREVIA: NUEVOS VS. YA EXISTENTES
============================================================================*/

SELECT @TotalYaExistente = COUNT(*)
FROM #CargaHomologada C
WHERE EXISTS
(
    SELECT 1
    FROM dbo.VUI_Transaccion TX
    WHERE TX.VUI_Tramite = C.VUI_Tramite
      AND TX.Referencia = C.Referencia
      AND TX.FechaTransaccion = C.FechaTransaccion
);

SELECT
    @TotalOrigen AS TotalExtraido,
    @TotalPreparado AS TotalHomologado,
    @TotalYaExistente AS TotalYaExistente,
    @TotalPreparado - @TotalYaExistente AS TotalPendienteInsertar,
    @NombreEstadoDestino AS EstadoDestino,
    @NombreSolicitanteDestino AS SolicitanteDestino,
    @ConfirmarCarga AS ConfirmarCarga;

/*============================================================================
  8. IMPORTACIÓN TRANSACCIONAL E IDEMPOTENTE
============================================================================*/

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.VUI_Transaccion
    (
        VUI_Tramite,
        VUI_Estado,
        VUI_Solicitante,
        Referencia,
        FechaTransaccion,
        Activo
    )
    SELECT
        C.VUI_Tramite,
        C.VUI_Estado,
        C.VUI_Solicitante,
        C.Referencia,
        C.FechaTransaccion,
        1
    FROM #CargaHomologada C
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.VUI_Transaccion TX WITH (UPDLOCK, HOLDLOCK)
        WHERE TX.VUI_Tramite = C.VUI_Tramite
          AND TX.Referencia = C.Referencia
          AND TX.FechaTransaccion = C.FechaTransaccion
    );

    SET @TotalInsertado = @@ROWCOUNT;

    /* Validación posterior dentro de la misma transacción. */
    SELECT @TotalDestinoPosterior = COUNT(*)
    FROM #CargaHomologada C
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.VUI_Transaccion TX
        WHERE TX.VUI_Tramite = C.VUI_Tramite
          AND TX.Referencia = C.Referencia
          AND TX.FechaTransaccion = C.FechaTransaccion
          AND TX.Activo = 1
    );

    IF @TotalDestinoPosterior <> @TotalPreparado
    BEGIN
        THROW 50016,
              'La conciliación posterior no coincide con el total homologado.',
              1;
    END;

    IF @TotalInsertado <> (@TotalPreparado - @TotalYaExistente)
    BEGIN
        THROW 50017,
              'La cantidad insertada no coincide con la cantidad pendiente calculada.',
              1;
    END;

    /* Resumen por bloque y trámite dentro de la operación. */
    SELECT
        C.BloqueOrigen AS Bloque,
        C.TramiteOrigen AS Tramite,
        COUNT(*) AS RegistrosExtraidos,
        SUM
        (
            CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM dbo.VUI_Transaccion TX
                    WHERE TX.VUI_Tramite = C.VUI_Tramite
                      AND TX.Referencia = C.Referencia
                      AND TX.FechaTransaccion = C.FechaTransaccion
                      AND TX.Activo = 1
                )
                THEN 1 ELSE 0
            END
        ) AS RegistrosConciliados
    FROM #CargaHomologada C
    GROUP BY
        C.BloqueOrigen,
        C.TramiteOrigen
    ORDER BY
        C.BloqueOrigen,
        C.TramiteOrigen;

    IF @ConfirmarCarga = 1
    BEGIN
        COMMIT TRANSACTION;

        SELECT
            N'ÉXITO: Carga confirmada mediante COMMIT.' AS Resultado,
            @TotalOrigen AS TotalExtraido,
            @TotalYaExistente AS TotalOmitidoPorExistencia,
            @TotalInsertado AS TotalInsertado,
            @TotalDestinoPosterior AS TotalConciliado;
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION;

        SELECT
            N'SIMULACIÓN CORRECTA: Se realizó ROLLBACK. No se conservaron cambios.' AS Resultado,
            @TotalOrigen AS TotalExtraido,
            @TotalYaExistente AS TotalOmitidoPorExistencia,
            @TotalInsertado AS TotalQueSeInsertaria,
            @TotalDestinoPosterior AS TotalConciliadoDuranteSimulacion;
    END;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS ErrorNumero,
        ERROR_LINE() AS ErrorLinea,
        ERROR_MESSAGE() AS ErrorMensaje,
        N'ABORTO SEGURO: La operación fue revertida completamente.' AS Estado;

    THROW;
END CATCH;
GO
