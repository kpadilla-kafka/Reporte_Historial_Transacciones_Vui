USE [VUI_TransaccionesDB];
GO

/******************************************************************************
 Proyecto      : Dashboard Gobernanza
 Reporte       : Reporte 3

 Procedimiento : dbo.sp_DashboardGobernanza_Reporte3

 Descripción:
     Obtiene el histórico mensual de transacciones de la Ventanilla Única de
     Inversión (VUI), agrupadas por bloque, trámite y año.

     El procedimiento muestra:
        - "ST" para períodos anteriores a la fecha de habilitación del trámite.
        - "0" cuando el trámite estaba habilitado pero no tuvo transacciones.
        - La cantidad correspondiente cuando existen registros.

 Ambiente:
     Desarrollo

 Parámetros:
     @FechaInicio : Fecha inicial del rango a consultar.
     @FechaFin    : Fecha final del rango a consultar.
     @Bloque      : Nombre del bloque a consultar. Si es NULL o 'Todos',
                    consulta todos los bloques.
     @Tramite     : Nombre del trámite a consultar. Si es NULL o 'Todos',
                    consulta todos los trámites.

 Resultado:
     El procedimiento devuelve una matriz con la siguiente estructura:

        Consecutivo
        OrdenBloque
        Bloque
        OrdenTramite
        Tramite
        Anio
        ENE
        FEB
        MAR
        ABR
        MAY
        JUN
        JUL
        AGO
        SEP
        OCT
        NOV
        DIC
        Cantidad

 Historial de cambios:
 ------------------------------------------------------------------------------
 Fecha        Autor               Descripción
 ----------  ------------------  -----------------------------------------------
 2026-07-09  Katiana Padilla     Creación inicial del procedimiento.
 ------------------------------------------------------------------------------
******************************************************************************/

CREATE OR ALTER PROCEDURE dbo.sp_DashboardGobernanza_Reporte3
(
    @FechaInicio DATE,
    @FechaFin DATE,
    @Bloque NVARCHAR(255) = NULL,
    @Tramite NVARCHAR(255) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /*===========================================================
      1. Normalización de parámetros
    ===========================================================*/
    SET @Bloque = ISNULL(@Bloque, N'Todos');
    SET @Tramite = ISNULL(@Tramite, N'Todos');

    /*===========================================================
      2. Validaciones básicas
    ===========================================================*/
    IF @FechaInicio IS NULL
    BEGIN
        RAISERROR('La fecha inicial es obligatoria.', 16, 1);
        RETURN;
    END;

    IF @FechaFin IS NULL
    BEGIN
        RAISERROR('La fecha final es obligatoria.', 16, 1);
        RETURN;
    END;

    IF @FechaInicio > @FechaFin
    BEGIN
        RAISERROR('La fecha inicial no puede ser mayor a la fecha final.', 16, 1);
        RETURN;
    END;

    /*===========================================================
      3. Generación del rango mensual
    ===========================================================*/
    ;WITH Meses AS
    (
        SELECT DATEFROMPARTS(YEAR(@FechaInicio), MONTH(@FechaInicio), 1) AS FechaMes

        UNION ALL

        SELECT DATEADD(MONTH, 1, FechaMes)
        FROM Meses
        WHERE FechaMes < DATEFROMPARTS(YEAR(@FechaFin), MONTH(@FechaFin), 1)
    ),

    /*===========================================================
      4. Base de consulta:
         combinación de trámites activos contra todos los meses
    ===========================================================*/
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

    /*===========================================================
      5. Conteo real de transacciones por trámite, año y mes
    ===========================================================*/
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

    /*===========================================================
      6. Resultado mensual:
         aplica regla ST / 0 / Cantidad
    ===========================================================*/
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

    /*===========================================================
      7. Salida final para SSRS
    ===========================================================*/
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
END;
GO


/*===========================================================
  Prueba rápida del procedimiento
===========================================================*/
EXEC dbo.sp_DashboardGobernanza_Reporte3
    @FechaInicio = '2022-01-01',
    @FechaFin = '2026-12-31',
    @Bloque = N'Todos',
    @Tramite = N'Todos';
GO
