USE [VUI_TransaccionesDB];
GO

/*==============================================================================
  Proyecto: Dashboard Gobernanza - Reporte 3
  Query: Prueba_Detalle_Mensual_Tramites.sql

  Descripción:
      Genera el detalle mensual de transacciones por bloque, trámite y año,
      mostrando ST cuando el trámite aún no estaba habilitado, 0 cuando no tuvo
      transacciones y la cantidad cuando existan registros.

  Ambiente:
      Desarrollo
==============================================================================*/

SET NOCOUNT ON;

/* Parámetros de prueba */
DECLARE @FechaInicio DATE = '2022-01-01';
DECLARE @FechaFin    DATE = '2026-12-31';
DECLARE @Bloque      NVARCHAR(255) = N'Todos';
DECLARE @Tramite     NVARCHAR(255) = N'Todos';

;WITH Meses AS
(
    SELECT DATEFROMPARTS(YEAR(@FechaInicio), MONTH(@FechaInicio), 1) AS FechaMes

    UNION ALL

    SELECT DATEADD(MONTH, 1, FechaMes)
    FROM Meses
    WHERE FechaMes < DATEFROMPARTS(YEAR(@FechaFin), MONTH(@FechaFin), 1)
),
Base AS
(
    SELECT
        B.OrdenBloque,
        B.Nombre AS Bloque,
        T.OrdenTramite,
        T.Nombre AS Tramite,
        T.FechaHabilitacion,
        YEAR(M.FechaMes) AS Anio,
        MONTH(M.FechaMes) AS Mes,
        M.FechaMes,
        EOMONTH(M.FechaMes) AS FinMes,
        T.VUI_Tramite
    FROM dbo.VUI_Tramite T
    INNER JOIN dbo.VUI_Bloque B
        ON B.VUI_Bloque = T.VUI_Bloque
    CROSS JOIN Meses M
    WHERE T.Activo = 1
      AND B.Activo = 1
      AND (@Bloque = N'Todos' OR B.Nombre = @Bloque)
      AND (@Tramite = N'Todos' OR T.Nombre = @Tramite)
),
Conteo AS
(
    SELECT
        TX.VUI_Tramite,
        YEAR(TX.FechaTransaccion) AS Anio,
        MONTH(TX.FechaTransaccion) AS Mes,
        COUNT(*) AS Cantidad
    FROM dbo.VUI_Transaccion TX
    WHERE TX.Activo = 1
      AND TX.FechaTransaccion >= @FechaInicio
      AND TX.FechaTransaccion < DATEADD(DAY, 1, @FechaFin)
    GROUP BY
        TX.VUI_Tramite,
        YEAR(TX.FechaTransaccion),
        MONTH(TX.FechaTransaccion)
),
Resultado AS
(
    SELECT
        B.OrdenBloque,
        B.Bloque,
        B.OrdenTramite,
        B.Tramite,
        B.Anio,
        B.Mes,
        CASE
            WHEN B.FechaHabilitacion IS NOT NULL
             AND B.FinMes < B.FechaHabilitacion
                THEN N'ST'
            ELSE CAST(ISNULL(C.Cantidad, 0) AS NVARCHAR(20))
        END AS ValorMes,
        CASE
            WHEN B.FechaHabilitacion IS NOT NULL
             AND B.FinMes < B.FechaHabilitacion
                THEN 0
            ELSE ISNULL(C.Cantidad, 0)
        END AS ValorNumerico
    FROM Base B
    LEFT JOIN Conteo C
        ON C.VUI_Tramite = B.VUI_Tramite
       AND C.Anio = B.Anio
       AND C.Mes = B.Mes
)
SELECT
    ROW_NUMBER() OVER (
        PARTITION BY Bloque, Tramite
        ORDER BY Anio
    ) AS Consecutivo,

    OrdenBloque,
    Bloque,
    OrdenTramite,
    Tramite,
    Anio,

    MAX(CASE WHEN Mes = 1  THEN ValorMes END) AS ENE,
    MAX(CASE WHEN Mes = 2  THEN ValorMes END) AS FEB,
    MAX(CASE WHEN Mes = 3  THEN ValorMes END) AS MAR,
    MAX(CASE WHEN Mes = 4  THEN ValorMes END) AS ABR,
    MAX(CASE WHEN Mes = 5  THEN ValorMes END) AS MAY,
    MAX(CASE WHEN Mes = 6  THEN ValorMes END) AS JUN,
    MAX(CASE WHEN Mes = 7  THEN ValorMes END) AS JUL,
    MAX(CASE WHEN Mes = 8  THEN ValorMes END) AS AGO,
    MAX(CASE WHEN Mes = 9  THEN ValorMes END) AS SEP,
    MAX(CASE WHEN Mes = 10 THEN ValorMes END) AS OCT,
    MAX(CASE WHEN Mes = 11 THEN ValorMes END) AS NOV,
    MAX(CASE WHEN Mes = 12 THEN ValorMes END) AS DIC,

    SUM(ValorNumerico) AS Cantidad
FROM Resultado
GROUP BY
    OrdenBloque,
    Bloque,
    OrdenTramite,
    Tramite,
    Anio
ORDER BY
    OrdenBloque,
    OrdenTramite,
    Anio
OPTION (MAXRECURSION 0);
