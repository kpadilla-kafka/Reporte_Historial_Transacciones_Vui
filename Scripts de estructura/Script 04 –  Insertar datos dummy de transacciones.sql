--/*Este script es exclusivamente para el ambiente de Desarrollo y tiene como finalidad poblar la base con datos ficticios para validar el funcionamiento del Reporte 3. 
--/*No debe ejecutarse en ambientes de pruebas finales o producción.

-------------------------------
USE [VUI_TransaccionesDB];
GO

/*==============================================================================
  Proyecto: Dashboard Gobernanza - Reporte 3
  Script: 04_Insertar_Datos_Dummy_Transacciones.sql

  Descripción:
      Inserta datos ficticios de transacciones para validar el Reporte 3 en SSRS.
      Estos datos permiten probar conteos por año, mes, trámite, bloque, estado y
      solicitante.

  Ambiente:
      Desarrollo

  Consideraciones:
      - No ejecutar en Producción.
      - Los datos son ficticios.
      - Se insertan únicamente si no existen datos dummy previos.
      - Las referencias generadas utilizan el prefijo DUMMY-R3.
      - Se actualiza FechaHabilitacion únicamente cuando está NULL.
==============================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    /*===========================================================
      1. Validación de catálogos requeridos
    ===========================================================*/
    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Tramite WHERE Activo = 1)
        RAISERROR('No existen trámites activos en dbo.VUI_Tramite.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Estado WHERE Activo = 1)
        RAISERROR('No existen estados activos en dbo.VUI_Estado.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Solicitante WHERE Activo = 1)
        RAISERROR('No existen solicitantes activos en dbo.VUI_Solicitante.', 16, 1);


    /*===========================================================
      2. Asignar fechas dummy de habilitación
         Solo cuando el campo está NULL
    ===========================================================*/
    UPDATE dbo.VUI_Tramite
    SET FechaHabilitacion =
        CASE
            WHEN Nombre IN (N'Apertura de Empresa') THEN '2024-01-01'
            WHEN Nombre IN (N'APC', N'APC-M', N'APC-R', N'APT') THEN '2023-06-01'
            WHEN Nombre LIKE N'D1%' THEN '2025-01-01'
            WHEN Nombre IN (N'Fichas de Emergencia') THEN '2024-07-01'
            ELSE '2022-01-01'
        END
    WHERE FechaHabilitacion IS NULL;


    /*===========================================================
      3. Insertar transacciones dummy
         Evita duplicar si el script ya fue ejecutado
    ===========================================================*/
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.VUI_Transaccion
        WHERE Referencia LIKE N'DUMMY-R3-%'
    )
    BEGIN
        ;WITH Meses AS
        (
            SELECT CAST('2022-01-01' AS DATE) AS FechaMes
            UNION ALL
            SELECT DATEADD(MONTH, 1, FechaMes)
            FROM Meses
            WHERE FechaMes < '2026-12-01'
        ),
        Numeros AS
        (
            SELECT 1 AS N
            UNION ALL
            SELECT N + 1
            FROM Numeros
            WHERE N < 8
        ),
        Base AS
        (
            SELECT
                T.VUI_Tramite,
                T.Nombre AS Tramite,
                T.FechaHabilitacion,
                M.FechaMes,
                YEAR(M.FechaMes) AS Anio,
                MONTH(M.FechaMes) AS Mes,
                ABS(CHECKSUM(T.VUI_Tramite, YEAR(M.FechaMes), MONTH(M.FechaMes))) % 9 AS CantidadMes
            FROM dbo.VUI_Tramite T
            CROSS JOIN Meses M
            WHERE T.Activo = 1
              AND M.FechaMes >= T.FechaHabilitacion
        ),
        DatosGenerados AS
        (
            SELECT
                B.VUI_Tramite,
                B.FechaMes,
                B.Anio,
                B.Mes,
                N.N,
                DATEADD(DAY, (N.N * 3) % 25, B.FechaMes) AS FechaTransaccion
            FROM Base B
            INNER JOIN Numeros N
                ON N.N <= B.CantidadMes
            WHERE B.CantidadMes > 0
        )
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
            DG.VUI_Tramite,
            E.VUI_Estado,
            S.VUI_Solicitante,
            CONCAT(
                N'DUMMY-R3-',
                DG.VUI_Tramite, N'-',
                DG.Anio, N'-',
                RIGHT('00' + CAST(DG.Mes AS VARCHAR(2)), 2), N'-',
                DG.N
            ) AS Referencia,
            DG.FechaTransaccion,
            1 AS Activo
        FROM DatosGenerados DG
        CROSS APPLY
        (
            SELECT TOP 1 VUI_Estado
            FROM dbo.VUI_Estado
            WHERE Activo = 1
            ORDER BY CHECKSUM(NEWID())
        ) E
        CROSS APPLY
        (
            SELECT TOP 1 VUI_Solicitante
            FROM dbo.VUI_Solicitante
            WHERE Activo = 1
            ORDER BY CHECKSUM(NEWID())
        ) S
        OPTION (MAXRECURSION 0);
    END;


    COMMIT TRANSACTION;

    SELECT 'ÉXITO: Datos dummy insertados o ya existentes correctamente.' AS Resultado;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS ErrorNumero,
        ERROR_MESSAGE() AS ErrorMensaje,
        'ABORTO SEGURO: No se consolidaron cambios incompletos.' AS Estado;
END CATCH;
GO


/*===========================================================
  Validación rápida
===========================================================*/
SELECT COUNT(*) AS TotalTransaccionesDummy
FROM dbo.VUI_Transaccion
WHERE Referencia LIKE N'DUMMY-R3-%';

SELECT
    YEAR(FechaTransaccion) AS Anio,
    MONTH(FechaTransaccion) AS Mes,
    COUNT(*) AS Cantidad
FROM dbo.VUI_Transaccion
WHERE Referencia LIKE N'DUMMY-R3-%'
GROUP BY
    YEAR(FechaTransaccion),
    MONTH(FechaTransaccion)
ORDER BY
    Anio,
    Mes;

SELECT TOP 20
    B.Nombre AS Bloque,
    T.Nombre AS Tramite,
    T.FechaHabilitacion,
    TX.Referencia,
    TX.FechaTransaccion
FROM dbo.VUI_Transaccion TX
INNER JOIN dbo.VUI_Tramite T
    ON T.VUI_Tramite = TX.VUI_Tramite
INNER JOIN dbo.VUI_Bloque B
    ON B.VUI_Bloque = T.VUI_Bloque
WHERE TX.Referencia LIKE N'DUMMY-R3-%'
ORDER BY TX.FechaTransaccion;
